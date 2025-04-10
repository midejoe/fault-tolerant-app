FROM ruby:2.7-alpine

WORKDIR /app
COPY . .

RUN apk add --no-cache build-base \
    && bundle install

# Add health check endpoint
RUN echo -e "get '/health' do\n  content_type :json\n  { status: 'healthy', version: ENV['APP_VERSION'] || '1.0.0' }.to_json\nend" >> lib/cats.rb

EXPOSE 8000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
