-- Adds 5,000,000 more rows to each main table for the Aurora Blue/Green Upgrade POC
-- This script starts from current max IDs to avoid duplicate key errors
-- Run this AFTER existing data is already loaded

-- Get current max IDs and add 5M rows to each table
DO $$
DECLARE
    max_category_id INTEGER;
    max_user_id INTEGER;
    max_customer_id INTEGER;
    max_product_id INTEGER;
    max_order_id INTEGER;
    max_review_id INTEGER;
BEGIN
    -- Get current max IDs
    SELECT COALESCE(MAX(id), 0) INTO max_category_id FROM categories;
    SELECT COALESCE(MAX(id), 0) INTO max_user_id FROM users;
    SELECT COALESCE(MAX(id), 0) INTO max_customer_id FROM customers;
    SELECT COALESCE(MAX(id), 0) INTO max_product_id FROM products;
    SELECT COALESCE(MAX(id), 0) INTO max_order_id FROM orders;
    SELECT COALESCE(MAX(id), 0) INTO max_review_id FROM reviews;

    -- Add 5,000,000 categories
    INSERT INTO categories (name, description)
    SELECT
      'Category ' || (max_category_id + gs),
      (ARRAY[
        'Seasonal bouquet arrangements',
        'Garden-themed and greenery products',
        'Gift bundles and extras',
        'Potted plants and succulents',
        'Accessories and packaging',
        'Premium floral services',
        'Bulk order discounts',
        'Custom arrangements',
        'Seasonal decorations',
        'Floral education materials'
      ])[floor(random()*10+1)::int]
    FROM generate_series(1,5000000) AS gs;

    -- Add 5,000,000 users
    INSERT INTO users (username, email, created_at)
    SELECT 'user' || (max_user_id + gs), 'user' || (max_user_id + gs) || '@example.com', now() - (gs || ' days')::interval
    FROM generate_series(1,5000000) AS gs;

    -- Add 5,000,000 customers
    INSERT INTO customers (name, email, country, joined_at)
    SELECT
      first_name || ' ' || last_name,
      lower(first_name || '.' || last_name) || (max_customer_id + gs) || '@example.com',
      (ARRAY['USA','Canada','UK','Australia','Germany','France','Netherlands','Japan','Brazil','India','Spain','Italy','Mexico','Sweden','South Korea','China','Russia','Argentina','South Africa','New Zealand'])[floor(random()*20+1)::int],
      now() - (floor(random()*365)::int || ' days')::interval
    FROM (
      SELECT
        (ARRAY['Alex','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Cameron','Dana','Harper','Logan','Charlie','Quinn','Parker','Evelyn','Benjamin','Chloe','Samuel','Lily','Noah','Zoe','Caleb','Nora','Theo','Maya','Lucas','Madison','Jackson','Aubrey'])[floor(random()*30+1)::int] AS first_name,
        (ARRAY['Smith','Johnson','Brown','Williams','Jones','Miller','Davis','Garcia','Rodriguez','Wilson','Reed','Hayes','Reid','Poe','Lane','Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane'])[floor(random()*35+1)::int] AS last_name,
        gs
      FROM generate_series(1,5000000) AS gs
    ) s;

    -- Add 5,000,000 products
    INSERT INTO products (name, category_id, price, inventory)
    SELECT
      (ARRAY['Red','Pink','White','Yellow','Lavender','Peach','Coral','Orange','Blue','Cream','Purple','Gold','Silver','Black','Green','Burgundy','Champagne','Rose Gold','Mint','Sage'])[floor(random()*20+1)::int]
      || ' '
      || (ARRAY['Rose','Tulip','Lily','Daisy','Orchid','Peony','Sunflower','Carnation','Iris','Hydrangea','Chrysanthemum','Gerbera','Alstroemeria','Delphinium','Gladiolus','Anemone','Calla Lily','Bird of Paradise','Proteas','Kangaroo Paw'])[floor(random()*20+1)::int]
      || ' Bouquet ' || (max_product_id + gs),
      floor(random()*(max_category_id + 5000000)+1)::int,
      round((random()*150 + 15)::numeric, 2),
      floor(random()*500 + 20)::int
    FROM generate_series(1,5000000) AS gs;

    -- Add inventory rows for new products
    INSERT INTO inventory (product_id, quantity, updated_at)
    SELECT id, inventory, now() - (floor(random()*90)::int || ' days')::interval
    FROM products WHERE id > max_product_id;

    -- Add 5,000,000 orders
    INSERT INTO orders (customer_id, created_at, status)
    SELECT
      floor(random()*(max_customer_id + 5000000)+1)::int,
      now() - (floor(random()*365)::int || ' days')::interval,
      (ARRAY['pending','processing','shipped','delivered','cancelled','refunded','on_hold','backordered'])[floor(random()*8+1)::int]
    FROM generate_series(1,5000000);

    -- Add order items for new orders (2-6 items per order)
    WITH order_list AS (
      SELECT id AS order_id FROM orders WHERE id > max_order_id
    )
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    SELECT
      o.order_id,
      floor(random()*(max_product_id + 5000000)+1)::int,
      floor(random()*5+1)::int,
      (SELECT price FROM products WHERE id = floor(random()*(max_product_id + 5000000)+1)::int LIMIT 1)
    FROM order_list o
    CROSS JOIN generate_series(1, 6) AS n
    WHERE n <= 2 + floor(random()*5)::int;

    -- Add payments for new orders
    INSERT INTO payments (order_id, amount, method, paid_at)
    SELECT
      o.id,
      coalesce(sum(oi.unit_price * oi.quantity), 0),
      (ARRAY['credit_card','paypal','bank_transfer','apple_pay','google_pay','venmo','cash_on_delivery','check'])[floor(random()*8+1)::int],
      o.created_at + (floor(random()*14)::int || ' days')::interval
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.id
    WHERE o.id > max_order_id
    GROUP BY o.id, o.created_at;

    -- Add shipments for new orders
    INSERT INTO shipments (order_id, shipped_at, carrier, tracking_code)
    SELECT
      o.id,
      CASE WHEN o.status IN ('shipped','delivered') THEN o.created_at + (floor(random()*10 + 1)::int || ' days')::interval ELSE NULL END,
      (ARRAY['UPS','FedEx','DHL','USPS','Amazon Logistics','Canada Post','Royal Mail','Australia Post','DPD','Hermes'])[floor(random()*10+1)::int],
      'TRK' || lpad((floor(random()*90000000)+10000000)::text, 8, '0')
    FROM orders o WHERE o.id > max_order_id;

    -- Add 5,000,000 reviews
    INSERT INTO reviews (product_id, author, rating, comment, created_at)
    SELECT
      floor(random()*(max_product_id + 5000000)+1)::int,
      (ARRAY['Mia','Noah','Liam','Emma','Olivia','Ethan','Ava','Sophia','Isabella','Mason','Evelyn','Benjamin','Chloe','Samuel','Lily','Zoe','Caleb','Nora','Theo','Maya','Lucas','Madison','Jackson','Aubrey','Carter','Grace','Henry','Ella','Sebastian','Scarlett'])[floor(random()*30+1)::int]
      || ' '
      || (ARRAY['Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane','Brooks','Fisher','Hunter','Jordan','Kennedy','Mitchell','Parker','Phillips','Russell','Simmons'])[floor(random()*30+1)::int],
      floor(random()*5+1)::int,
      (ARRAY[
        'Beautiful arrangement that exceeded my expectations',
        'Fast delivery and great quality flowers',
        'Customer service was exceptional and helpful',
        'Very fresh flowers that lasted much longer than expected',
        'Would definitely order again from this seller',
        'The bouquet was even more vibrant than in the photos',
        'Perfect for the special occasion I ordered it for',
        'Packaging was beautiful and protected the flowers well',
        'Exactly as pictured and described on the website',
        'Wonderful fragrance and stunning visual appeal',
        'Great value for money with high quality blooms',
        'Delivery was prompt and flowers arrived in perfect condition',
        'The recipient was absolutely delighted with the arrangement',
        'Professional presentation and attention to detail',
        'Fresh, vibrant colors that brightened up the room',
        'Excellent communication throughout the ordering process',
        'Flowers lasted well beyond the expected vase life',
        'Beautiful craftsmanship and artistic design',
        'Perfect size and scale for the space it was intended for',
        'Outstanding quality that made the occasion truly special'
      ])[floor(random()*20+1)::int],
      now() - (floor(random()*365)::int || ' days')::interval
    FROM generate_series(1,5000000);

END $$;