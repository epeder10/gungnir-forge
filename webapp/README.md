# Web Application with Login and Application Management

A simple web application with user authentication and application management features.

## Features

- User registration and login
- JWT-based authentication
- Create, read, update, and delete applications
- Each application gets a unique API key
- PostgreSQL database for data persistence

## Prerequisites

### For Docker Setup
- Docker and Docker Compose

### For Local Development
- Node.js (v14 or higher)
- PostgreSQL database
- npm or yarn

## Docker Setup (Recommended)

### Quick Start with Docker Compose

1. Clone the repository and navigate to the webapp directory:
```bash
cd webapp
```

2. Copy the environment example file:
```bash
cp .env.example .env
```

3. Build and start all services:
```bash
docker-compose up --build
```

The application will be available at:
- Frontend: http://localhost
- Backend API: http://localhost:3001
- PostgreSQL: localhost:5432

### Development with Docker

For development with hot-reloading:
```bash
docker-compose -f docker-compose.dev.yml up
```

### Production Deployment

For production:
```bash
# Set production environment variables
export JWT_SECRET=your-production-secret-key

# Run with production compose file
docker-compose up -d
```

## Local Setup Instructions (Alternative)

### 1. Database Setup

First, create a PostgreSQL database:

```sql
createdb appmanager
```

### 2. Backend Configuration

Navigate to the backend directory:
```bash
cd webapp/backend
```

Update the `.env` file with your PostgreSQL connection details:
```
DATABASE_URL=postgresql://username:password@localhost:5432/appmanager
JWT_SECRET=your-secret-key-change-in-production
PORT=3001
```

### 3. Start the Backend

```bash
cd webapp/backend
npm start
```

The backend server will start on http://localhost:3001

### 4. Start the Frontend

In a new terminal:
```bash
cd webapp/frontend
npm start
```

The frontend will start on http://localhost:3000

## Usage

1. Open http://localhost:3000 in your browser
2. Register a new account or login
3. Once logged in, you can:
   - Create new applications
   - View all your applications with their API keys
   - Edit application details
   - Delete applications

## API Endpoints

- `POST /api/register` - Register a new user
- `POST /api/login` - Login user
- `GET /api/user` - Get current user (authenticated)
- `GET /api/applications` - Get all applications (authenticated)
- `POST /api/applications` - Create new application (authenticated)
- `PUT /api/applications/:id` - Update application (authenticated)
- `DELETE /api/applications/:id` - Delete application (authenticated)

## Docker Commands

### Useful Docker Commands

```bash
# Stop all containers
docker-compose down

# Stop and remove volumes (database data)
docker-compose down -v

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Rebuild specific service
docker-compose build backend
docker-compose build frontend

# Access PostgreSQL database
docker exec -it webapp-postgres psql -U postgres -d appmanager

# Access backend container
docker exec -it webapp-backend sh

# Access frontend container  
docker exec -it webapp-frontend sh
```

## Security Notes

- Change the JWT_SECRET in production
- Use HTTPS in production with proper SSL certificates
- Consider adding rate limiting
- Implement proper input validation
- Add CSRF protection for production use
- Use Docker secrets for sensitive environment variables in production
- Regularly update base images for security patches