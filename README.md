# Project Setup Guide

Follow these steps exactly in order to set up and run the project on your computer.

## Prerequisites

Before starting, ensure you have the following installed on your machine:

- **Python** (Version 3.11.4)
- **PostgreSQL** (Version 18.6 or compatible)
- **Flutter & Dart SDK** (Flutter 3.41.6, Dart 3.11.4)

---

## Step 1: Database Setup

1. Open your local **PostgreSQL** application (like pgAdmin or your terminal shell) and log in.
2. Create a brand new, empty database. Take note of the **Database Name**, your **Username**, and your **Password**.

---

## Step 2: Environment Configuration (.env)

1. Open the project folder (`application1`) in your code editor.
2. Create a new file named exactly `.env` in the root of the `application1` folder.
3. Copy and paste the text below into that file, replacing the right side with your actual database details:

```text
DB_NAME=your_database_name_here
DB_USER=your_postgres_username_here
DB_PASSWORD=your_postgres_password_here
DB_HOST=localhost
DB_PORT=5432
```

---

## Step 3: Python Backend Setup

Open a terminal window, navigate to the `application1` folder, and run these commands:

### 1. Create a Virtual Environment

```bash
python -m venv .venv
```

### 2. Activate the Environment (Choose based on your OS)

- **Windows (Command Prompt):**
  ```cmd
  .venv\Scripts\activate
  ```
- **Windows (PowerShell):**
  ```powershell
  .venv\Scripts\Activate.ps1
  ```

### 3. Install All Required Packages

```bash
python -m pip install -r requirements.txt
```

---

## Step 4: How to Run the Application

### 1. Launch the Django Backend

In the same terminal where your environment is active, navigate to the backend folder, update the database tables, and start the server:

```bash
# Move into the backend directory
cd backend1

# Setup database tables
python manage.py migrate

# Start the server
python manage.py runserver
```

_The backend server is now running at:_ `http://127.0.0`

### 2. Launch the Flutter Frontend

Open a **completely new, separate terminal window** and run these commands to launch the app UI:

```bash
# First, make sure you navigate to the project directory
cd application1/frontend

# Fetch frontend assets
flutter pub get

# Launch the app
flutter run
```

---

### Note for Developers

When installing a new Python library, always ensure you are in the root directory (`application1`) with your virtual environment active, and run the following command to update the dependencies list:

```bash
python -m pip freeze > requirements.txt
```

## Exiting the Virtual Environment

When you are done working on the backend project and want to exit the virtual environment, run:

```bash
deactivate
```

This will return your terminal back to your normal global system settings.
