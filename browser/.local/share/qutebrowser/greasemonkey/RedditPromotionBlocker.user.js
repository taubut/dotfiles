// ==UserScript==
// @name         Reddit Promotion Blocker
// @namespace    http://tampermonkey.net/
// @version      0.6.0
// @description  Blocks all promoted advertisements on Reddit (vanilla JS version)
// @author       Aiden Charles (modified for qutebrowser)
// @match        *://reddit.com/*
// @match        *://www.reddit.com/*
// @match        *://old.reddit.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    console.log("Reddit promotion blocker script is running!");

    function hidePromotedContent() {
        // New Reddit (sh.reddit.com style)
        document.querySelectorAll('shreddit-ad-post').forEach(el => el.style.display = 'none');
        document.querySelectorAll('shreddit-comments-page-ad').forEach(el => el.style.display = 'none');
        document.querySelectorAll('shreddit-comment-tree-ad').forEach(el => el.style.display = 'none');
        document.querySelectorAll("shreddit-async-loader[bundlename='sidebar_ad']").forEach(el => el.style.display = 'none');
        document.querySelectorAll("shreddit-async-loader[bundlename='feed_announcement']").forEach(el => el.style.display = 'none');

        // Promoted link containers
        document.querySelectorAll('.promotedlink').forEach(el => el.style.display = 'none');
        document.querySelectorAll('.adsense-ad').forEach(el => {
            if (el.parentElement && el.parentElement.parentElement) {
                el.parentElement.parentElement.style.display = 'none';
            }
        });

        // Old Reddit
        if (window.location.hostname === 'old.reddit.com') {
            document.querySelectorAll('.ad-container').forEach(el => {
                if (el.parentElement) el.parentElement.style.display = 'none';
            });
            document.querySelectorAll('.promoted-tag').forEach(el => {
                if (el.parentElement && el.parentElement.parentElement) {
                    el.parentElement.parentElement.style.display = 'none';
                }
            });
            // Find "promoted" spans and hide parent post
            document.querySelectorAll('span').forEach(span => {
                if (span.textContent.toLowerCase().includes('promoted')) {
                    let parent = span;
                    for (let i = 0; i < 5 && parent; i++) parent = parent.parentElement;
                    if (parent) parent.style.display = 'none';
                }
            });
        }

        // New Reddit promoted posts (search for promoted text in any element)
        document.querySelectorAll('[data-before-content="advertisement"]').forEach(el => {
            let parent = el;
            for (let i = 0; i < 3 && parent; i++) parent = parent.parentElement;
            if (parent) parent.style.display = 'none';
        });

        // Generic promoted post detection
        document.querySelectorAll('article, div[data-testid="post-container"]').forEach(post => {
            if (post.querySelector('[data-promoted="true"]') ||
                post.querySelector('.promoted') ||
                post.textContent.includes('promoted')) {
                const promotedBadge = post.querySelector('span');
                if (promotedBadge && promotedBadge.textContent.trim().toLowerCase() === 'promoted') {
                    post.style.display = 'none';
                }
            }
        });
    }

    // Run on page load
    hidePromotedContent();

    // Watch for dynamically loaded content
    const observer = new MutationObserver(hidePromotedContent);
    observer.observe(document.body, { childList: true, subtree: true });
})();
