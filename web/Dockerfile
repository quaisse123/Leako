# Frontend Dockerfile (build static files, serve with nginx)

# Build stage: compile the React app
FROM node:20-alpine AS build
WORKDIR /app
# Install dependencies
COPY package*.json ./
RUN npm ci
# Copy source and build
COPY . .
RUN npm run build

# Runtime stage: serve static files with nginx
FROM nginx:alpine
# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy build output to nginx public folder
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
