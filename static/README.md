# Static Assets Directory

This directory contains static assets (CSS, JavaScript, images) for the CRM-ADLC application.

Static files are served via FastAPI's StaticFiles mount at `/static/`.

## Usage

Place your static files in this directory:
- CSS files: `static/css/`
- JavaScript files: `static/js/`
- Images: `static/images/`

Reference in templates:
```html
<link rel="stylesheet" href="/static/css/styles.css">
<script src="/static/js/app.js"></script>
<img src="/static/images/logo.png" alt="Logo">
```
