-- Additional sample data for Aurora POC
-- Run this after schema.sql and seed_data.sql for more rows.

-- Add more categories
INSERT INTO categories (name, description) VALUES
  ('Luxury Bouquets', 'Premium arrangements for special occasions'),
  ('Eco-Friendly', 'Sustainable and recycled packaging flowers');

-- Add more users
INSERT INTO users (username, email, created_at)
SELECT 'extra_user' || gs, 'extra_user' || gs || '@example.com', now() - (gs || ' hours')::interval
FROM generate_series(1, 20) AS gs;

-- Add more customers
INSERT INTO customers (name, email, country, joined_at)
SELECT
  first_name || ' ' || last_name,
  lower(first_name || '.' || last_name) || '@example.com',
  (ARRAY['Spain','Italy','Mexico','Sweden','South Korea'])[floor(random()*5+1)::int],
  now() - (floor(random()*180)::int || ' days')::interval
FROM (
  SELECT
    (ARRAY['Harper','Logan','Charlie','Quinn','Parker'])[floor(random()*5+1)::int] AS first_name,
    (ARRAY['Reed','Hayes','Reid','Poe','Lane'])[floor(random()*5+1)::int] AS last_name
  FROM generate_series(1, 20)
) s;

-- Add more products
INSERT INTO products (name, category_id, price, inventory)
SELECT
  (ARRAY['Sunset','Velvet','Sparkle','Grace','Harmony'])[floor(random()*5+1)::int]
  || ' '
  || (ARRAY['Roses','Lilies','Tulips','Orchids','Mixed'])[floor(random()*5+1)::int]
  || ' Collection',
  floor(random()*7+1)::int,
  round((random()*90 + 10)::numeric, 2),
  floor(random()*120 + 30)::int
FROM generate_series(1, 20);

-- Add inventory entries for new products
INSERT INTO inventory (product_id, quantity, updated_at)
SELECT id, inventory, now() - (floor(random()*15)::int || ' days')::interval
FROM products
WHERE id > 100;

-- Add additional orders and order items
INSERT INTO orders (customer_id, created_at, status)
SELECT floor(random()*120+1)::int, now() - (floor(random()*45)::int || ' days')::interval,
  (ARRAY['pending','processing','shipped','delivered'])[floor(random()*4+1)::int]
FROM generate_series(1, 30);

WITH new_order_list AS (
  SELECT id AS order_id FROM orders ORDER BY id DESC LIMIT 30
)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
  o.order_id,
  p.id,
  floor(random()*2+1)::int,
  p.price
FROM new_order_list o
CROSS JOIN LATERAL (
  SELECT id, price FROM products ORDER BY random() LIMIT 1
) p
CROSS JOIN generate_series(1, 3) AS n
WHERE n <= 1 + floor(random()*3)::int;

-- Add payments for new orders
INSERT INTO payments (order_id, amount, method, paid_at)
SELECT
  o.id,
  coalesce(sum(oi.unit_price * oi.quantity), 0),
  (ARRAY['credit_card','paypal','bank_transfer'])[floor(random()*3+1)::int],
  o.created_at + (floor(random()*5)::int || ' days')::interval
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
WHERE o.id > (SELECT max(id) - 30 FROM orders)
GROUP BY o.id, o.created_at;

-- Add shipments for new orders
INSERT INTO shipments (order_id, shipped_at, carrier, tracking_code)
SELECT
  o.id,
  CASE WHEN o.status IN ('shipped','delivered') THEN o.created_at + (floor(random()*4 + 1)::int || ' days')::interval ELSE NULL END,
  (ARRAY['UPS','FedEx','DHL','USPS'])[floor(random()*4+1)::int],
  'TRK' || lpad((floor(random()*900000)+100000)::text, 6, '0')
FROM orders o
WHERE o.id > (SELECT max(id) - 30 FROM orders);

-- Add more reviews
INSERT INTO reviews (product_id, author, rating, comment, created_at)
SELECT
  floor(random()*120+1)::int,
  (ARRAY['Evelyn','Benjamin','Chloe','Samuel','Lily','Noah','Zoe','Caleb','Nora','Theo'])[floor(random()*10+1)::int]
  || ' '
  || (ARRAY['Fox','Reynolds','Wells','Moss','Hayden','Cole','Reed','Frost','Myles','Kane'])[floor(random()*10+1)::int],
  floor(random()*5+1)::int,
  (ARRAY[
    'Fantastic quality',
    'Delivered faster than expected',
    'Great flowers and service',
    'Perfect for the event',
    'Very happy with my order',
    'Beautiful presentation',
    'Fresh and fragrant',
    'Exceeded my expectations',
    'Nice packaging',
    'Wonderful customer support'
  ])[floor(random()*10+1)::int],
  now() - (floor(random()*90)::int || ' days')::interval
FROM generate_series(1, 30);
