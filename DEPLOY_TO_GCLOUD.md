# Deploying Gemini LangGraph App to Google Cloud (Docker + Cloud Run)

This guide describes how to deploy both the backend (FastAPI/LangGraph) and frontend (React/Vite) of the Gemini LangGraph Quickstart app to Google Cloud using Docker and Cloud Run. It includes best practices, options, and a step-by-step TODO checklist.

---

## Deployment Architecture Options

### Option 1 (Recommended)
- **Backend:** Deployed as a Docker container on Google Cloud Run
- **Frontend:** Built and deployed to a static host (Google Cloud Storage, Firebase Hosting, Vercel, or Netlify)

### Option 2
- **Backend:** Deployed as a Docker container on Google Cloud Run
- **Frontend:** Built and bundled into the backend Docker image, served by FastAPI (as in local production)

---

## Step-by-Step Deployment Plan

### 1. Build the Frontend for Production
```sh
cd frontend
npm run build
# Output: frontend/dist
```

### 2. Prepare Backend Dockerfile
If serving FE from BE, copy the built frontend into the Docker image.

**Example Dockerfile:**
```Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/src ./src
COPY backend/start_backend.sh ./

# Copy built frontend (optional)
COPY frontend/dist ./frontend/dist

# Expose port
EXPOSE 8000

# Set environment variables
ENV PYTHONPATH=/app/src

# Start the backend
CMD ["bash", "start_backend.sh"]
```

### 3. (One-Time) Create the Artifact Registry Repo (if needed)

If you have not already created the Docker repo, run:

```sh
gcloud artifacts repositories create gemini-langgraph \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for Gemini LangGraph app"
```

### 4. Build and Upload Docker Image to Artifact Registry with Google Cloud Build

From your project root (with all local changes, including any patches), run:

```sh
gcloud builds submit --tag us-central1-docker.pkg.dev/gen-lang-client-0515475267/gemini-langgraph/gemini-langgraph-app:latest .
```

This command will:
- Upload your current local codebase (including any manual fixes or patches) to Google Cloud Build
- Build the Docker image in the cloud
- Push it to your Artifact Registry repo `gemini-langgraph` in `us-central1`

### 5. Deploy to Google Cloud Run

```sh
gcloud run deploy gemini-langgraph-app \
  --image us-central1-docker.pkg.dev/gen-lang-client-0515475267/gemini-langgraph/gemini-langgraph-app:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=your_key_here
```

- Replace `your_key_here` with your actual Gemini API key (or use Cloud Secret Manager for production security).
- This will create a public Cloud Run service at a generated HTTPS URL.

### 6. (Frontend Static Hosting Option)
- Upload `frontend/dist` to your preferred static host (GCS, Firebase, Vercel, Netlify).
- Configure the frontend to call the deployed backend Cloud Run URL.

---

## Deployment Progress Log

**Completed Steps:**
- Authenticated with Google Cloud and set project/region.
- Created Artifact Registry repository `gemini-langgraph` in `us-central1`.
- Built and pushed Docker image to Artifact Registry using `gcloud builds submit`.
- Created Secret Manager secret `gemini-langgraph-gemini-api-key` for the `GEMINI_API_KEY`.
- Granted `roles/secretmanager.secretAccessor` to the Cloud Run service account (`171469023174-compute@developer.gserviceaccount.com`) **without conditions**.
- Deployed Cloud Run service `gemini-langgraph-app` (deployment failed due to missing `DATABASE_URI`).
- Deleted Cloud Run service `gemini-langgraph-app` to prevent unwanted costs.

---

## Secret Management for API Keys

Sensitive API keys (such as `GEMINI_API_KEY`) are stored securely in Google Cloud Secret Manager.

**Steps:**
1. Created secret:
   ```sh
   echo "YOUR_ACTUAL_API_KEY" | gcloud secrets create gemini-langgraph-gemini-api-key --data-file=- --replication-policy=automatic
   # Or add a new version:
   echo "YOUR_ACTUAL_API_KEY" | gcloud secrets versions add gemini-langgraph-gemini-api-key --data-file=-
   ```
2. Granted Secret Manager access to the Cloud Run service account:
   ```sh
   gcloud projects add-iam-policy-binding gen-lang-client-0515475267 \
     --member="serviceAccount:171469023174-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```
3. Referenced the secret in deployment:
   ```sh
   --set-secrets GEMINI_API_KEY=gemini-langgraph-gemini-api-key:latest
   ```

---

## TODO: Remaining Steps for Production Deployment

- [ ] **Provision a Postgres database** (e.g., Cloud SQL) and obtain the connection URI.
- [ ] **Provision a Redis instance** (e.g., Memorystore) and obtain the connection URI.
- [ ] **Update deployment command** to include required environment variables:
  - `DATABASE_URI=postgres://USER:PASSWORD@HOST:PORT/DBNAME`
  - `REDIS_URL=redis://HOST:PORT`
- [ ] **Redeploy Cloud Run service** with all necessary secrets and environment variables.
- [ ] **Test deployment**: Ensure backend starts, frontend is served, and all features work.
- [ ] **Optional: Set up monitoring, error reporting, and cost controls.**
- [ ] **Clean up unused resources** (e.g., test databases, Redis, old secrets, Artifact Registry images) to avoid costs.

---

## Open Source Project URL

The official Gemini LangGraph Quickstart repository:

[https://github.com/langchain-ai/graph-quickstart-gemini](https://github.com/langchain-ai/graph-quickstart-gemini)

---

## Notes
- For production, secure your API keys using Google Cloud Secret Manager or Cloud Run environment variables.
- If you want a single domain for both FE and BE, serve FE from BE in Docker; otherwise, use static hosting for FE for better performance and scalability.
- Update CORS and API endpoints in your frontend as needed.

---

Feel free to adapt this plan for your project’s needs. For help with any step, see Google Cloud Run, Google Cloud Storage, or Docker documentation.
