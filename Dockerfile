# Multi-stage Dockerfile for smtp4dev
# This builds the application from source, unlike Dockerfile.linux which expects pre-built binaries

# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Install Node.js (required for the ClientApp build)
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Copy project files
COPY smtpserver/ ./smtpserver/
COPY imapserver/ ./imapserver/
COPY Rnwood.Smtp4dev/ ./Rnwood.Smtp4dev/

# Restore dependencies
RUN dotnet restore Rnwood.Smtp4dev/Rnwood.Smtp4dev.csproj

# Build and publish the application
RUN dotnet publish Rnwood.Smtp4dev/Rnwood.Smtp4dev.csproj \
    -c Release \
    -o /app \
    --no-restore

# Stage 2: Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
RUN apt update && \
    apt install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app /app

RUN mkdir -p /smtp4dev && chown -R app:app /smtp4dev
VOLUME ["/smtp4dev"]

WORKDIR /

ENV XDG_CONFIG_HOME=/
ENV ASPNETCORE_HTTP_PORTS=80
ENV SERVEROPTIONS__URLS=http://*:80
ENV DOTNET_USE_POLLING_FILE_WATCHER=true

EXPOSE 80
EXPOSE 25
EXPOSE 143
EXPOSE 110

ENTRYPOINT ["dotnet", "/app/Rnwood.Smtp4dev.dll"]
