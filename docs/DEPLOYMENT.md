# Zenskar Integration - Deployment Guide

## Quick Start

### 1. Initial Setup
```bash
# Clone and setup
git clone <repository>
cd zenskar-integration

# Run setup script
./start.sh
```

### 2. Configure Environment
```bash
# Copy environment template
cp env.example .env

# Edit .env with your credentials:
# - DATABASE_URL: Get from Neon dashboard
# - STRIPE_API_KEY: Get from Stripe dashboard  
# - STRIPE_WEBHOOK_SECRET: Get after webhook setup
```

### 3. Start Services

**Terminal 1 - API Server:**
```bash
./run_api.sh
```

**Terminal 2 - Sync Worker:**
```bash
./run_worker.sh
```

**Terminal 3 - Kafka (if not running):**
```bash
docker-compose up -d
```

### 4. Setup Stripe Webhook

**Option A - Using ngrok:**
```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Start tunnel
ngrok http 8000

# Copy HTTPS URL to Stripe Dashboard → Webhooks
# Add endpoint: https://your-url.ngrok.io/webhooks/stripe
# Select events: customer.created, customer.updated, customer.deleted
# Copy webhook secret to .env
```

**Option B - Using Stripe CLI:**
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe  # macOS

# Login to Stripe
stripe login

# Forward webhooks
stripe listen --forward-to localhost:8000/webhooks/stripe

# Copy webhook secret to .env
```

## Testing the Integration

### 1. Create Customer via API
```bash
curl -X POST http://localhost:8000/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'
```

**Expected Flow:**
1. Customer created in local database
2. Event published to Kafka
3. Worker processes event
4. Customer created in Stripe
5. Mapping stored between IDs

### 2. Create Customer in Stripe Dashboard
1. Go to Stripe Dashboard → Customers
2. Create new customer
3. Webhook should trigger
4. Customer synced to local database

### 3. Verify Two-Way Sync
- Update customer in API → Should sync to Stripe
- Update customer in Stripe → Should sync to API
- Delete customer in API → Should delete in Stripe
- Delete customer in Stripe → Should delete in API

## Production Deployment

### 1. Environment Variables
```bash
# Production .env
DATABASE_URL=postgresql://user:pass@prod-db.neon.tech/db
STRIPE_API_KEY=sk_live_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
KAFKA_BOOTSTRAP_SERVERS=kafka-cluster:9092
APP_ENV=production
LOG_LEVEL=INFO
```

### 2. Database Setup
```bash
# Run migrations
alembic upgrade head

# Verify tables created
psql $DATABASE_URL -c "\dt"
```

### 3. Kafka Setup
- Use managed Kafka service (Confluent Cloud, AWS MSK)
- Configure proper security and authentication
- Set up monitoring and alerting

### 4. Application Deployment
```bash
# Install production dependencies
pip install -r requirements.txt

# Start with production server
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000

# Start workers (multiple instances for scaling)
python -m app.workers.sync_worker &
python -m app.workers.sync_worker &
```

### 5. Monitoring Setup
- Add Sentry for error tracking
- Add Prometheus metrics
- Set up log aggregation
- Configure health checks

## Troubleshooting

### Common Issues

**1. Kafka Connection Failed**
```bash
# Check if Kafka is running
docker ps | grep kafka

# Check Kafka logs
docker logs kafka

# Restart Kafka
docker-compose restart kafka
```

**2. Database Connection Failed**
- Verify DATABASE_URL in .env
- Check if IP is whitelisted in Neon
- Test connection: `psql $DATABASE_URL`

**3. Stripe Webhook Not Working**
- Verify webhook secret in .env
- Check ngrok/Stripe CLI is running
- Review FastAPI logs for webhook errors
- Test webhook: `stripe trigger customer.created`

**4. Worker Not Processing Events**
- Check Kafka consumer group
- Verify topic exists: `kafka-topics --list`
- Check worker logs for errors

### Debug Commands

```bash
# Check all services
docker ps

# View Kafka topics
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# View application logs
tail -f logs/app.log

# Test API health
curl http://localhost:8000/health
```

## Scaling Considerations

### 1. Horizontal Scaling
- Deploy multiple API instances behind load balancer
- Run multiple worker instances for high throughput
- Use Kafka partitioning for parallel processing

### 2. Database Optimization
- Configure connection pooling
- Add read replicas for queries
- Implement database sharding if needed

### 3. Monitoring & Alerting
- Set up Prometheus metrics
- Configure Grafana dashboards
- Add alerting for failed syncs
- Monitor queue depth and processing time

## Security Considerations

### 1. API Security
- Add authentication/authorization
- Implement rate limiting
- Use HTTPS in production
- Validate all inputs

### 2. Database Security
- Use connection encryption
- Implement proper access controls
- Regular security updates
- Backup and recovery procedures

### 3. Integration Security
- Secure webhook endpoints
- Validate webhook signatures
- Use idempotency keys
- Implement retry logic with backoff

## Maintenance

### 1. Regular Tasks
- Monitor sync status
- Check for failed events
- Review error logs
- Update dependencies

### 2. Backup Strategy
- Database backups
- Configuration backups
- Event log retention
- Disaster recovery plan

### 3. Updates
- Test in staging environment
- Gradual rollout
- Monitor for issues
- Rollback plan if needed
