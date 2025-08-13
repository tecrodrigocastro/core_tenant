# Base image PHP-FPM
FROM php:8.3-fpm

# Argumentos para o usuário
ARG user=wallace
ARG uid=1000

# Set timezone e frontend não-interativo
ENV TZ=America/Sao_Paulo \
    DEBIAN_FRONTEND=noninteractive

# Instalar dependências do sistema e ferramentas necessárias
RUN apt-get update && apt-get install -y \
    supervisor \
    procps \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    gnupg \
    lsb-release \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Node.js e NPM
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Instalar extensões PHP necessárias para Laravel
RUN docker-php-ext-install pdo_pgsql pgsql pdo_mysql mbstring exif pcntl bcmath gd sockets intl zip soap

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Redis PHP extension
RUN pecl install -o -f redis && docker-php-ext-enable redis

# Criar usuário para rodar a aplicação
RUN useradd -u $uid -G www-data,root -m -d /home/$user $user && \
    mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Cria e dá permissão nos diretórios de log/run do Supervisor
RUN mkdir -p /var/log/supervisor /var/run/supervisor /run/php \
    && chown -R $user:$user /var/log/supervisor /var/run/supervisor /run/php

# Copiar código do Laravel para a pasta do servidor
COPY . /var/www

# ---- Stripe CLI (opcional, como no seu original) ----
RUN curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor > /usr/share/keyrings/stripe.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" > /etc/apt/sources.list.d/stripe.list \
 && apt-get update && apt-get install -y stripe \
 && rm -rf /var/lib/apt/lists/*

# Ajustar permissões do Laravel (pasta storage e bootstrap/cache)
RUN chown -R $user:www-data /var/www/storage /var/www/bootstrap/cache

# Trocar para usuário não-root para segurança
USER wallace
