# Render Deployment Guide

This guide explains how to set up the Web Service on Render to host the Flutter Web application using a lightweight Node.js server.

## Overview
- **Build**: Handled by GitHub Actions (`.github/workflows/deploy_web.yml`).
- **Serve**: Handled by Render (Node.js).
- **Logs**: Forwarded from client to Render logs via `/log` endpoint.

## Render Service Configuration

1. **Create a New Web Service** in Render Dashboard.
2. **Connect your Repository**.
3. **Configure Settings**:

   | Setting | Value |
   | :--- | :--- |
   | **Name** | `expense-tracker-web` (or your choice) |
   | **Runtime** | **Node** |
   | **Root Directory** | `server` |
   | **Build Command** | `npm install` |
   | **Start Command** | `node server.js` |
   | **Auto-Deploy** | **Yes** (Recommended) |

## Important Notes

- **GitHub Token**: Ensure the `GITHUB_TOKEN` has **Read and write permissions** in your repository settings (Settings -> Actions -> General -> Workflow permissions).
- **First Run**: The first deployment might fail or show 404 until the GitHub Action runs successfully and populates `server/public`. After pushing these changes, wait for the Action to complete, then trigger a manual deploy on Render if needed (or let Auto-Deploy handle it).
- **Logs**: To view client logs, go to the **Logs** tab in your Render service. Look for `[CLIENT_LOG]`.
