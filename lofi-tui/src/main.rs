use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Flex, Layout, Margin, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Padding, Paragraph, Wrap},
    Frame, Terminal,
};
use ratatui_image::{picker::Picker, protocol::StatefulProtocol, Resize, StatefulImage};
use serde::Deserialize;
use std::{io, process::Stdio, time::Duration};
use tokio::process::Command;

// Catppuccin Macchiato colors
const BASE: Color = Color::Rgb(36, 39, 58);
const MANTLE: Color = Color::Rgb(30, 32, 48);
const SURFACE0: Color = Color::Rgb(54, 58, 79);
const SURFACE1: Color = Color::Rgb(73, 77, 100);
const OVERLAY0: Color = Color::Rgb(110, 115, 141);
const SUBTEXT0: Color = Color::Rgb(165, 173, 203);
const TEXT: Color = Color::Rgb(202, 211, 245);
const LAVENDER: Color = Color::Rgb(183, 189, 248);
const SAPPHIRE: Color = Color::Rgb(125, 196, 228);
const PEACH: Color = Color::Rgb(245, 169, 127);
const FLAMINGO: Color = Color::Rgb(240, 198, 198);
const MAUVE: Color = Color::Rgb(198, 160, 246);

#[derive(Debug, Deserialize)]
struct StreamInfo {
    title: String,
    id: String,
}

struct App {
    streams: Vec<StreamInfo>,
    filtered_indices: Vec<usize>,
    list_state: ListState,
    thumbnail: Option<StatefulProtocol>,
    picker: Option<Picker>,
    loading: bool,
    should_quit: bool,
    last_selected: Option<usize>,
    filter_mode: bool,
    filter_query: String,
}

impl App {
    fn new() -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        let picker = Picker::from_query_stdio().ok();

        Self {
            streams: Vec::new(),
            filtered_indices: Vec::new(),
            list_state,
            thumbnail: None,
            picker,
            loading: true,
            should_quit: false,
            last_selected: None,
            filter_mode: false,
            filter_query: String::new(),
        }
    }

    fn update_filter(&mut self) {
        if self.filter_query.is_empty() {
            self.filtered_indices = (0..self.streams.len()).collect();
        } else {
            let query = self.filter_query.to_lowercase();
            self.filtered_indices = self
                .streams
                .iter()
                .enumerate()
                .filter(|(_, s)| s.title.to_lowercase().contains(&query))
                .map(|(i, _)| i)
                .collect();
        }
        if !self.filtered_indices.is_empty() {
            self.list_state.select(Some(0));
        } else {
            self.list_state.select(None);
        }
    }

    fn selected_stream_index(&self) -> Option<usize> {
        self.list_state
            .selected()
            .and_then(|i| self.filtered_indices.get(i).copied())
    }

    fn next(&mut self) {
        if self.filtered_indices.is_empty() {
            return;
        }
        let i = match self.list_state.selected() {
            Some(i) => {
                if i >= self.filtered_indices.len() - 1 {
                    0
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.list_state.select(Some(i));
    }

    fn previous(&mut self) {
        if self.filtered_indices.is_empty() {
            return;
        }
        let i = match self.list_state.selected() {
            Some(i) => {
                if i == 0 {
                    self.filtered_indices.len() - 1
                } else {
                    i - 1
                }
            }
            None => 0,
        };
        self.list_state.select(Some(i));
    }

    fn needs_thumbnail_reload(&self) -> bool {
        self.last_selected != self.selected_stream_index()
    }

    fn mark_thumbnail_loaded(&mut self) {
        self.last_selected = self.selected_stream_index();
    }
}

fn parse_title(title: &str) -> (String, String) {
    // Split on " - " if present
    if let Some(pos) = title.find(" - ") {
        let name = title[..pos].trim().to_string();
        let desc = title[pos + 3..].trim().to_string();
        return (name, desc);
    }

    // Otherwise try to find where description starts after emoji
    let chars: Vec<char> = title.chars().collect();
    let mut emoji_end = 0;
    let mut found_emoji = false;

    for (i, c) in chars.iter().enumerate() {
        if c.is_ascii_alphanumeric() || c.is_ascii_whitespace() {
            if found_emoji && i > 0 {
                emoji_end = i;
                break;
            }
        } else {
            found_emoji = true;
            emoji_end = i + 1;
        }
    }

    if found_emoji && emoji_end > 0 && emoji_end < chars.len() {
        let name: String = chars[..emoji_end].iter().collect();
        let desc: String = chars[emoji_end..].iter().collect();
        return (name.trim().to_string(), desc.trim().to_string());
    }

    (title.to_string(), String::new())
}

#[tokio::main]
async fn main() -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();

    let streams = fetch_streams().await?;
    app.streams = streams;
    app.filtered_indices = (0..app.streams.len()).collect();
    app.loading = false;

    if !app.streams.is_empty() && app.picker.is_some() {
        if let Ok(thumb) = load_thumbnail(&app.streams[0].id, app.picker.as_mut().unwrap()).await {
            app.thumbnail = Some(thumb);
            app.mark_thumbnail_loaded();
        }
    }

    let result = run_app(&mut terminal, &mut app).await;

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    result
}

async fn run_app(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
) -> Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if event::poll(Duration::from_millis(50))? {
            match event::read()? {
                Event::Key(key) if key.kind == KeyEventKind::Press => {
                    if app.filter_mode {
                        match key.code {
                            KeyCode::Esc => {
                                app.filter_mode = false;
                                app.filter_query.clear();
                                app.update_filter();
                            }
                            KeyCode::Enter => {
                                app.filter_mode = false;
                            }
                            KeyCode::Backspace => {
                                app.filter_query.pop();
                                app.update_filter();
                            }
                            KeyCode::Char(c) => {
                                app.filter_query.push(c);
                                app.update_filter();
                            }
                            _ => {}
                        }
                    } else {
                        match key.code {
                            KeyCode::Char('q') => {
                                app.should_quit = true;
                            }
                            KeyCode::Esc => {
                                if !app.filter_query.is_empty() {
                                    app.filter_query.clear();
                                    app.update_filter();
                                } else {
                                    app.should_quit = true;
                                }
                            }
                            KeyCode::Char('/') => {
                                app.filter_mode = true;
                            }
                            KeyCode::Down | KeyCode::Char('j') => {
                                app.next();
                            }
                            KeyCode::Up | KeyCode::Char('k') => {
                                app.previous();
                            }
                            KeyCode::Enter => {
                                if let Some(idx) = app.selected_stream_index() {
                                    let id = app.streams[idx].id.clone();
                                    play_stream(&id).await?;
                                }
                            }
                            _ => {}
                        }
                    }
                }
                Event::Resize(_, _) => {
                    app.thumbnail = None;
                    app.last_selected = None;
                }
                _ => {}
            }
        }

        if app.needs_thumbnail_reload() && app.picker.is_some() {
            if let Some(idx) = app.selected_stream_index() {
                let id = app.streams[idx].id.clone();
                if let Ok(thumb) = load_thumbnail(&id, app.picker.as_mut().unwrap()).await {
                    app.thumbnail = Some(thumb);
                    app.mark_thumbnail_loaded();
                }
            }
        }

        if app.should_quit {
            break;
        }
    }
    Ok(())
}

fn ui(f: &mut Frame, app: &mut App) {
    let area = f.area();

    // Fill background
    f.render_widget(Block::default().style(Style::default().bg(MANTLE)), area);

    // Main layout
    let outer = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),
            Constraint::Min(0),
            Constraint::Length(2),
        ])
        .split(area);

    // Header
    let header = Paragraph::new(Line::from(vec![
        Span::styled(" lofi girl", Style::default().fg(FLAMINGO).add_modifier(Modifier::BOLD)),
        Span::styled(" stream picker", Style::default().fg(SUBTEXT0)),
    ]))
    .style(Style::default().bg(MANTLE));
    f.render_widget(header, outer[0]);

    // Content area
    let content = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(45), Constraint::Percentage(55)])
        .split(outer[1]);

    render_stream_list(f, app, content[0]);
    render_preview(f, app, content[1]);
    render_footer(f, app, outer[2]);

    if app.filter_mode {
        render_filter_popup(f, app, area);
    }
}

fn render_stream_list(f: &mut Frame, app: &mut App, area: Rect) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(SURFACE1))
        .title(Span::styled(" streams ", Style::default().fg(LAVENDER).add_modifier(Modifier::BOLD)))
        .padding(Padding::horizontal(1))
        .style(Style::default().bg(BASE));

    let inner = block.inner(area);
    f.render_widget(block, area);

    let items: Vec<ListItem> = app
        .filtered_indices
        .iter()
        .enumerate()
        .map(|(list_idx, &stream_idx)| {
            let stream = &app.streams[stream_idx];
            let (name, _) = parse_title(&stream.title);
            let is_selected = app.list_state.selected() == Some(list_idx);

            let name_style = if is_selected {
                Style::default().fg(FLAMINGO).add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(TEXT)
            };

            ListItem::new(Line::from(Span::styled(name, name_style)))
        })
        .collect();

    let list = List::new(items)
        .highlight_style(Style::default().bg(SURFACE0))
        .highlight_symbol("  ");

    f.render_stateful_widget(list, inner, &mut app.list_state);

    if !app.filter_query.is_empty() {
        let filter_text = format!(" /{} ", app.filter_query);
        let filter_area = Rect::new(
            area.x + area.width - filter_text.len() as u16 - 2,
            area.y,
            filter_text.len() as u16 + 1,
            1,
        );
        let filter_widget = Paragraph::new(filter_text)
            .style(Style::default().fg(PEACH).bg(SURFACE0));
        f.render_widget(filter_widget, filter_area);
    }
}

fn render_preview(f: &mut Frame, app: &mut App, area: Rect) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(SURFACE1))
        .title(Span::styled(" preview ", Style::default().fg(SAPPHIRE).add_modifier(Modifier::BOLD)))
        .style(Style::default().bg(BASE));

    let inner = block.inner(area);
    f.render_widget(block, area);

    let preview_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(4)])
        .split(inner);

    let thumb_area = preview_layout[0];
    let info_area = preview_layout[1];

    if let Some(ref mut protocol) = app.thumbnail {
        // Calculate height for 4:3 image to fill width
        // 4:3 pixels with ~1:2 cell ratio = ~8:3 in cells
        let img_height = (thumb_area.width as f64 * 3.0 / 8.0) as u16;
        let img_height = img_height.min(thumb_area.height);

        let img_area = Rect::new(thumb_area.x, thumb_area.y, thumb_area.width, img_height);

        let image = StatefulImage::new().resize(Resize::Fit(None));
        f.render_stateful_widget(image, img_area, protocol);
    } else if app.loading {
        let loading = Paragraph::new("Loading streams...")
            .style(Style::default().fg(OVERLAY0))
            .alignment(Alignment::Center);
        f.render_widget(loading, thumb_area);
    } else {
        let loading = Paragraph::new("Loading...")
            .style(Style::default().fg(OVERLAY0))
            .alignment(Alignment::Center);
        f.render_widget(loading, thumb_area);
    }

    if let Some(idx) = app.selected_stream_index() {
        let stream = &app.streams[idx];
        let (name, desc) = parse_title(&stream.title);

        let mut lines = vec![
            Line::from(Span::styled(
                name,
                Style::default().fg(TEXT).add_modifier(Modifier::BOLD),
            )),
        ];

        if !desc.is_empty() {
            lines.push(Line::from(Span::styled(desc, Style::default().fg(SUBTEXT0))));
        } else {
            lines.push(Line::from(Span::styled("lofi girl", Style::default().fg(OVERLAY0))));
        }

        let info = Paragraph::new(lines)
            .alignment(Alignment::Center)
            .wrap(Wrap { trim: true });

        f.render_widget(info, info_area.inner(Margin::new(1, 0)));
    }
}

fn render_footer(f: &mut Frame, app: &App, area: Rect) {
    let help_items = if app.filter_mode {
        vec![("esc", "cancel"), ("enter", "confirm"), ("type", "filter")]
    } else {
        vec![("j/k", "navigate"), ("/", "filter"), ("enter", "play"), ("q", "quit")]
    };

    let spans: Vec<Span> = help_items
        .iter()
        .flat_map(|(key, action)| {
            vec![
                Span::styled(format!(" {} ", key), Style::default().fg(MAUVE).bg(SURFACE0)),
                Span::styled(format!(" {} ", action), Style::default().fg(SUBTEXT0)),
                Span::raw("  "),
            ]
        })
        .collect();

    let footer = Paragraph::new(Line::from(spans))
        .alignment(Alignment::Center)
        .style(Style::default().bg(MANTLE));

    f.render_widget(footer, area);
}

fn render_filter_popup(f: &mut Frame, app: &App, area: Rect) {
    let popup_width = 40u16.min(area.width - 4);
    let popup_height = 3u16;

    let popup_area = Rect::new(
        (area.width - popup_width) / 2,
        area.height / 3,
        popup_width,
        popup_height,
    );

    f.render_widget(Clear, popup_area);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(PEACH))
        .title(Span::styled(" filter ", Style::default().fg(PEACH).add_modifier(Modifier::BOLD)))
        .style(Style::default().bg(SURFACE0));

    let inner = block.inner(popup_area);
    f.render_widget(block, popup_area);

    let input = Paragraph::new(format!("/{}_", app.filter_query))
        .style(Style::default().fg(TEXT));
    f.render_widget(input, inner);
}

async fn fetch_streams() -> Result<Vec<StreamInfo>> {
    let output = Command::new("yt-dlp")
        .args([
            "--flat-playlist",
            "-I", "1:20",
            "https://www.youtube.com/@LofiGirl/streams",
            "-j",
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .await?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let streams: Vec<StreamInfo> = stdout
        .lines()
        .filter_map(|line| serde_json::from_str(line).ok())
        .collect();

    Ok(streams)
}

async fn load_thumbnail(video_id: &str, picker: &mut Picker) -> Result<StatefulProtocol> {
    let url = format!("https://img.youtube.com/vi/{}/hqdefault.jpg", video_id);
    let response = reqwest::get(&url).await?;
    let bytes = response.bytes().await?;

    let img = image::load_from_memory(&bytes)?;
    let protocol = picker.new_resize_protocol(img);

    Ok(protocol)
}

async fn play_stream(video_id: &str) -> Result<()> {
    let url = format!("https://www.youtube.com/watch?v={}", video_id);

    let _ = Command::new("pkill")
        .args(["-f", "mpv.*youtube.com/watch"])
        .output()
        .await;

    Command::new("mpv")
        .args(["--no-terminal", &url])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;

    Ok(())
}
