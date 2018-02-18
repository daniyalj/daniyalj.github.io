FROM ubuntu:latest
ENV NAME sysadvent

# Add multiverse repo. Install nginx, jekyll and some ruby-packages
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y nginx jekyll ruby-bundler ruby-jekyll-feed ruby-jekyll-paginate && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/www/html/* && \
  sed -i -e 's/listen 80 default/listen 8080 default/' \
         -e 's/listen \[::\]:80 default/listen \[::\]:8080 default/' /etc/nginx/sites-available/default

WORKDIR /build
ADD . /build

# Run Jekyll. Put result in nginx default document root
# Run Jekyll. Put result in nginx default document root
RUN \
  apt-get update && \
  bundle install --path=vendor && \
  bundle exec jekyll build --destination /var/www/html/sysadvent && \
  apt-get -y remove ruby-dev build-essential && \
  apt -y autoremove && \
  apt clean

# Start nginx in the foreground
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

RUN \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  mkdir -p /var/cache/nginx /var/lib/nginx /var/log/nginx && \
  chgrp -R 0 /var/cache/nginx /var/lib/nginx /var/log/nginx && \
  chmod -R g=u /var/cache/nginx /var/lib/nginx /var/log/nginx && \
  sed -i 's,/run/nginx.pid,/var/lib/nginx/nginx.pid,g' /etc/nginx/nginx.conf && \
  sed -i -e '/^user/d' /etc/nginx/nginx.conf
