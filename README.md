# Paperless conversion backend

A small service that powers the six tools that can't run in the browser:

| Tool in the app | Endpoint | Engine |
|---|---|---|
| Word / Excel / PPT → PDF | `POST /api/office-to-pdf` | LibreOffice headless |
| PDF → Word | `POST /api/pdf-to-word` | pdf2docx |
| PDF → Excel | `POST /api/pdf-to-excel` | pdfplumber + openpyxl |
| Protect (encrypt) | `POST /api/protect` | pikepdf (AES-256) |

Every other tool in the toolkit runs entirely in the browser and never calls this.

---

## Run it with Docker (recommended)

Docker bundles LibreOffice for you, so there's nothing else to install.

```bash
cd paperless-backend
docker build -t paperless-backend .
docker run -p 8080:8080 paperless-backend
```

The service is now at `http://localhost:8080`. Leave it running, open the toolkit
(`paperless-pdf-suite.html`) in your browser, and the six conversion tiles will work.

Check it's alive:

```bash
curl http://localhost:8080/
# {"service":"paperless-backend","status":"ok"}
```

---

## Run it without Docker

You need LibreOffice and Python 3.10+ installed.

1. Install LibreOffice
   - macOS: `brew install --cask libreoffice`
   - Ubuntu/Debian: `sudo apt install libreoffice qpdf`
   - Windows: download from libreoffice.org

2. Install the Python deps and start the server:

   ```bash
   cd paperless-backend
   pip install -r requirements.txt
   python app.py
   ```

   On Windows, `soffice` may not be on your PATH. Point the app at it:

   ```bash
   set SOFFICE_BIN="C:\Program Files\LibreOffice\program\soffice.exe"
   python app.py
   ```

---

## Connecting the front-end

Open `paperless-pdf-suite.html` and find this line near the top of the `<script>`:

```js
const API_BASE = "http://localhost:8080";
```

- Running locally: leave it as is.
- After you deploy the backend somewhere public: change it to that URL, e.g.
  `const API_BASE = "https://paperless-backend.onrender.com";`

Then set `ALLOW_ORIGIN` on the server to your site's URL so the browser allows the
calls (defaults to `*`, which is fine for local testing):

```bash
docker run -p 8080:8080 -e ALLOW_ORIGIN="https://your-site.example" paperless-backend
```

---

## Notes on quality

- **Office → PDF** is high fidelity — this is exactly what LibreOffice is built for.
- **PDF → Word** reflows a fixed layout back into editable paragraphs; great for
  text-heavy PDFs, less perfect for complex multi-column designs.
- **PDF → Excel** extracts detected tables. PDFs with clean ruled tables convert
  well; free-form text won't produce a meaningful spreadsheet.
- **Protect** uses AES-256. The same password is set for opening and for permissions.

## Limits & hardening (before going public)

- `MAX_UPLOAD_MB` (default 50) caps upload size.
- Put this behind HTTPS and rate-limit it.
- Consider running LibreOffice conversions in a queue if you expect heavy traffic —
  each conversion spawns a `soffice` process.
