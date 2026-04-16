-- Seed data for Aurora Blue/Green Upgrade POC

-- Categories
INSERT INTO categories (name, description) VALUES
  ('Bouquets', 'Seasonal bouquet arrangements'),
  ('Greenery', 'Garden-themed and greenery products'),
  ('Gift Boxes', 'Gift bundles and extras'),
  ('Plants', 'Potted plants and succulents'),
  ('Floral Supplies', 'Accessories and packaging');

-- 100 users
INSERT INTO users (username, email, created_at)
SELECT 'user' || gs, 'user' || gs || '@example.com', now() - (gs || ' days')::interval
FROM generate_series(1,100) AS gs;

-- 100 customers
INSERT INTO customers (name, email, country, joined_at)
SELECT
  first_name || ' ' || last_name,
  lower(first_name || '.' || last_name) || '@example.com',
  (ARRAY['USA','Canada','UK','Australia','Germany','France','Netherlands','Japan','Brazil','India'])[floor(random()*10+1)::int],
  now() - (floor(random()*365)::int || ' days')::interval
FROM (
  SELECT
    (ARRAY['Alex','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Cameron','Dana'])[floor(random()*10+1)::int] AS first_name,
    (ARRAY['Smith','Johnson','Brown','Williams','Jones','Miller','Davis','Garcia','Rodriguez','Wilson'])[floor(random()*10+1)::int] AS last_name
  FROM generate_series(1,100)
) s;

-- 100 products
INSERT INTO products (name, category_id, price, inventory)
SELECT
  (ARRAY['Red','Pink','White','Yellow','Lavender','Peach','Coral','Orange','Blue','Cream'])[floor(random()*10+1)::int]
  || ' '
  || (ARRAY['Rose','Tulip','Lily','Daisy','Orchid','Peony','Sunflower','Carnation','Iris','Hydrangea'])[floor(random()*10+1)::int]
  || ' Bouquet',
  floor(random()*5+1)::int,
  round((random()*85 + 15)::numeric, 2),
  floor(random()*180 + 20)::int
FROM generate_series(1,100) AS gs;

-- Inventory rows
INSERT INTO inventory (product_id, quantity, updated_at)
SELECT id, inventory, now() - (floor(random()*30)::int || ' days')::interval
FROM products;

-- 100 orders
INSERT INTO orders (customer_id, created_at, status)
SELECT
  floor(random()*100+1)::int,
  now() - (floor(random()*90)::int || ' days')::interval,
  (ARRAY['pending','processing','shipped','delivered','cancelled'])[floor(random()*5+1)::int]
FROM generate_series(1,100);

-- Order items: 1-4 items per order
WITH order_list AS (
  SELECT id AS order_id FROM orders
),
product_list AS (
  SELECT id, price FROM products
)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
  o.order_id,
  p.id,
  floor(random()*3+1)::int,
  p.price
FROM order_list o
CROSS JOIN generate_series(1, 4) AS n
CROSS JOIN LATERAL (SELECT * FROM product_list ORDER BY random() LIMIT 1) p
WHERE n <= 1 + floor(random()*4)::int;

-- Payments for each order
INSERT INTO payments (order_id, amount, method, paid_at)
SELECT
  o.id,
  coalesce(sum(oi.unit_price * oi.quantity), 0),
  (ARRAY['credit_card','paypal','bank_transfer'])[floor(random()*3+1)::int],
  o.created_at + (floor(random()*10)::int || ' days')::interval
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.created_at;

-- Shipments for each order
INSERT INTO shipments (order_id, shipped_at, carrier, tracking_code)
SELECT
  o.id,
  CASE WHEN o.status IN ('shipped','delivered') THEN o.created_at + (floor(random()*7 + 1)::int || ' days')::interval ELSE NULL END,
  (ARRAY['UPS','FedEx','DHL','USPS'])[floor(random()*4+1)::int],
  'TRK' || lpad((floor(random()*900000)+100000)::text, 6, '0')
FROM orders o;

-- 100 reviews
INSERT INTO reviews (product_id, author, rating, comment, created_at)
SELECT
  floor(random()*100+1)::int,
  (ARRAY['Mia','Noah','Liam','Emma','Olivia','Ethan','Ava','Sophia','Isabella','Mason'])[floor(random()*10+1)::int]
  || ' '
  || (ARRAY['Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter'])[floor(random()*10+1)::int],
  floor(random()*5+1)::int,
  (ARRAY[
    'Beautiful arrangement',
    'Fast delivery and great quality',
    'Customer service was friendly',
    'Very fresh flowers',
    'Would order again',
    'The bouquet lasted a long time',
    'Colors were more vibrant than expected',
    'Perfect for the occasion',
    'Packaging was nice',
    'Exactly as pictured'
  ])[floor(random()*10+1)::int],
  now() - (floor(random()*120)::int || ' days')::interval
FROM generate_series(1,100);