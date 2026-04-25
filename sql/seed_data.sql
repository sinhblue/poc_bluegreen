-- Seed data for Aurora Blue/Green Upgrade POC
-- Generates 7,000,000 rows per table with correct foreign-key relationships.

-- 7,000,000 categories
INSERT INTO categories (name, description)
SELECT
  'Category ' || gs,
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
  ])[((gs - 1) % 10) + 1]
FROM generate_series(1,7000000) AS gs;

-- 7,000,000 users
INSERT INTO users (username, email, created_at)
SELECT
  'user' || gs,
  'user' || gs || '@example.com',
  now() - ((gs % 365) || ' days')::interval
FROM generate_series(1,7000000) AS gs;

-- 7,000,000 customers
INSERT INTO customers (name, email, country, joined_at)
SELECT
  first_name || ' ' || last_name,
  lower(first_name || '.' || last_name) || gs || '@example.com',
  (ARRAY['USA','Canada','UK','Australia','Germany','France','Netherlands','Japan','Brazil','India','Spain','Italy','Mexico','Sweden','South Korea','China','Russia','Argentina','South Africa','New Zealand'])[((gs - 1) % 20) + 1],
  now() - ((gs % 365) || ' days')::interval
FROM (
  SELECT
    (ARRAY['Alex','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Cameron','Dana','Harper','Logan','Charlie','Quinn','Parker','Evelyn','Benjamin','Chloe','Samuel','Lily','Noah','Zoe','Caleb','Nora','Theo','Maya','Lucas','Madison','Jackson','Aubrey'])[((gs - 1) % 30) + 1] AS first_name,
    (ARRAY['Smith','Johnson','Brown','Williams','Jones','Miller','Davis','Garcia','Rodriguez','Wilson','Reed','Hayes','Reid','Poe','Lane','Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane'])[((gs - 1) % 35) + 1] AS last_name,
    (ARRAY['Smith','Johnson','Brown','Williams','Jones','Miller','Davis','Garcia','Rodriguez','Wilson','Reed','Hayes','Reid','Poe','Lane','Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane'])[((gs - 1) % 34) + 1] AS last_name,
    gs
  FROM generate_series(1,7000000) AS gs
) s;

-- 7,000,000 products
INSERT INTO products (name, category_id, price, inventory)
SELECT
  (ARRAY['Red','Pink','White','Yellow','Lavender','Peach','Coral','Orange','Blue','Cream','Purple','Gold','Silver','Black','Green','Burgundy','Champagne','Rose Gold','Mint','Sage'])[((gs - 1) % 20) + 1]
  || ' '
  || (ARRAY['Rose','Tulip','Lily','Daisy','Orchid','Peony','Sunflower','Carnation','Iris','Hydrangea','Chrysanthemum','Gerbera','Alstroemeria','Delphinium','Gladiolus','Anemone','Calla Lily','Bird of Paradise','Proteas','Kangaroo Paw'])[((gs - 1) % 20) + 1]
  || ' Bouquet ' || gs,
  ((gs - 1) % 7000000) + 1,
  round((random() * 85 + 15)::numeric, 2),
  floor(random() * 180 + 20)::int
FROM generate_series(1,7000000) AS gs;

-- Inventory rows for each product
INSERT INTO inventory (product_id, quantity, updated_at)
SELECT id, inventory, now() - ((id % 30) || ' days')::interval
FROM products
WHERE id <= 7000000;

-- 7,000,000 orders
INSERT INTO orders (customer_id, created_at, status)
SELECT
  ((gs - 1) % 7000000) + 1,
  now() - ((gs % 90) || ' days')::interval,
  (ARRAY['pending','processing','shipped','delivered','cancelled'])[((gs - 1) % 5) + 1]
FROM generate_series(1,7000000) AS gs;

-- 7,000,000 order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
  ((gs - 1) % 7000000) + 1,
  ((gs - 1) % 7000000) + 1,
  floor(random() * 4 + 1)::int,
  (SELECT price FROM products WHERE id = ((gs - 1) % 7000000) + 1)
FROM generate_series(1,7000000) AS gs;

-- 7,000,000 payments
INSERT INTO payments (order_id, amount, method, paid_at)
SELECT
  o.id,
  oi.unit_price * oi.quantity,
  (ARRAY['credit_card','paypal','bank_transfer'])[((o.id - 1) % 3) + 1],
  o.created_at + ((floor(random() * 10) + 1) || ' days')::interval
FROM orders o
JOIN order_items oi ON oi.order_id = o.id;

-- 7,000,000 shipments
INSERT INTO shipments (order_id, shipped_at, carrier, tracking_code)
SELECT
  o.id,
  CASE
    WHEN o.status IN ('shipped','delivered') THEN o.created_at + ((floor(random() * 7) + 1) || ' days')::interval
    ELSE NULL
  END,
  (ARRAY['UPS','FedEx','DHL','USPS'])[((o.id - 1) % 4) + 1],
  'TRK' || lpad(((o.id % 999999) + 1)::text, 6, '0')
FROM orders o;

-- 7,000,000 reviews
INSERT INTO reviews (product_id, author, rating, comment, created_at)
SELECT
  ((gs - 1) % 7000000) + 1,
  (ARRAY['Mia','Noah','Liam','Emma','Olivia','Ethan','Ava','Sophia','Isabella','Mason','Evelyn','Benjamin','Chloe','Samuel','Lily','Zoe','Caleb','Nora','Theo','Maya','Lucas','Madison','Jackson','Aubrey','Carter','Grace','Henry','Ella','Sebastian','Scarlett'])[((gs - 1) % 30) + 1]
  || ' '
  || (ARRAY['Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane','Brooks','Fisher','Hunter','Jordan','Kennedy','Mitchell','Parker','Phillips','Russell','Simmons'])[((gs - 1) % 30) + 1],
  || (ARRAY['Clark','Wright','Lopez','Hill','Scott','Green','Adams','Baker','Nelson','Carter','Fox','Reynolds','Wells','Moss','Hayden','Cole','Frost','Myles','Kane','Brooks','Fisher','Hunter','Jordan','Kennedy','Mitchell','Parker','Phillips','Russell','Simmons'])[((gs - 1) % 29) + 1],
  floor(random() * 5 + 1)::int,
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
  ])[((gs - 1) % 10) + 1],
  now() - ((gs % 120) || ' days')::interval
FROM generate_series(1,7000000) AS gs;