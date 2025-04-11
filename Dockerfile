# Use official Ruby Alpine image
FROM ruby:2.7-alpine

# Set working directory
WORKDIR /app

# Install dependencies
RUN apk add --update --no-cache \
    build-base \
    git

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 8000

# Start the application
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]