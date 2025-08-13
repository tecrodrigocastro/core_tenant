FROM php:8.3-fpm

# Args
ARG user=wallace
ARG uid=1000

# ---- System deps (inclui o que o gd/intl/zip precisam) ----
RUN apt-get update && apt-get install -y \
    git curl unzip zip ca-certificates gnupg lsb-release \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev \
    libxml2-dev libzip-dev zlib1g-dev \
    libicu-dev g++ \
 && rm -rf /var/lib/apt/lists/*

# ---- Node.js 20 + npm ----
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update && apt-get install -y nodejs \
 && npm i -g npm@latest \
 && rm -rf /var/lib/apt/lists/*

# ---- PHP extensions ----
# gd precisa ser configurado com suporte a freetype/jpeg/webp
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" \
    pdo_mysql mbstring exif pcntl bcmath gd sockets intl zip

# ---- Composer ----
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ---- Redis (PECL) ----
RUN pecl install -o -f redis \
 && docker-php-ext-enable redis \
 && rm -rf /tmp/pear

# ---- Stripe CLI (opcional, como no seu original) ----
RUN curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor > /usr/share/keyrings/stripe.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" > /etc/apt/sources.list.d/stripe.list \
 && apt-get update && apt-get install -y stripe \
 && rm -rf /var/lib/apt/lists/*

# ---- Usuário não-root ----
RUN useradd -G www-data,root -u $uid -d /home/$user $user \
 && mkdir -p /home/$user/.composer \
 && chown -R $user:$user /home/$user

WORKDIR /var/www
USER $user
