-- These will be run after the main database (POSTGRES_DB) is created
-- and after the user (POSTGRES_USER) is created with password (POSTGRES_PASSWORD)

-- Create additional databases
CREATE DATABASE pricing_production_cache;
CREATE DATABASE pricing_production_queue;
CREATE DATABASE pricing_production_cable;

-- Grant all privileges to our user for these additional databases
GRANT ALL PRIVILEGES ON DATABASE pricing_production_cache TO pricing;
GRANT ALL PRIVILEGES ON DATABASE pricing_production_queue TO pricing;
GRANT ALL PRIVILEGES ON DATABASE pricing_production_cable TO pricing;
