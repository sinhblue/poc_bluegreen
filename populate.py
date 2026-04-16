import random
from faker import Faker
from app import app
from models import db, User, Customer, Category, Product, Order, OrderItem, Inventory, Shipment, Payment, Review

fake = Faker()
PRODUCT_CATEGORIES = [
    ('Bouquets', 'Seasonal bouquet arrangements'),
    ('Greenery', 'Garden-themed and greenery products'),
    ('Gift Boxes', 'Gift bundles and extras'),
    ('Plants', 'Potted plants and succulents'),
    ('Floral Supplies', 'Accessories and packaging')
]

STATUS_OPTIONS = ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
PAYMENT_METHODS = ['credit_card', 'paypal', 'bank_transfer']
CARRIERS = ['UPS', 'FedEx', 'DHL', 'USPS']


def create_schema():
    with app.app_context():
        db.drop_all()
        db.create_all()


def seed_data():
    with app.app_context():
        categories = []
        for name, desc in PRODUCT_CATEGORIES:
            categories.append(Category(name=name, description=desc))
        db.session.add_all(categories)
        db.session.commit()

        users = [User(username=f'user{i}', email=f'user{i}@example.com') for i in range(1, 101)]
        db.session.add_all(users)

        customers = [
            Customer(name=fake.name(), email=fake.email(), country=fake.country())
            for _ in range(100)
        ]
        db.session.add_all(customers)
        db.session.commit()

        products = []
        for i in range(1, 101):
            category = random.choice(categories)
            products.append(
                Product(
                    name=f'{fake.color_name()} {fake.word().capitalize()} Bouquet',
                    category=category,
                    price=round(random.uniform(14.99, 99.99), 2),
                    inventory=random.randint(20, 200)
                )
            )
        db.session.add_all(products)
        db.session.commit()

        inventory_rows = [Inventory(product=product, quantity=product.inventory) for product in products]
        db.session.add_all(inventory_rows)
        db.session.commit()

        orders = []
        for _ in range(100):
            customer = random.choice(customers)
            order = Order(customer=customer, status=random.choice(STATUS_OPTIONS))
            db.session.add(order)
            orders.append(order)
        db.session.commit()

        order_items = []
        payments = []
        shipments = []
        for order in orders:
            item_count = random.randint(1, 4)
            current_items = []
            for _ in range(item_count):
                product = random.choice(products)
                quantity = random.randint(1, 3)
                current_items.append(
                    OrderItem(order=order, product=product, quantity=quantity, unit_price=product.price)
                )
            order_items.extend(current_items)
            payments.append(
                Payment(order=order, amount=sum(item.unit_price * item.quantity for item in current_items), method=random.choice(PAYMENT_METHODS))
            )
            shipments.append(
                Shipment(order=order, carrier=random.choice(CARRIERS), tracking_code=f'TRK{random.randint(100000,999999)}', shipped_at=fake.date_time_between(start_date='-30d', end_date='now'))
            )
        db.session.add_all(order_items)
        db.session.add_all(payments)
        db.session.add_all(shipments)
        db.session.commit()

        reviews = [
            Review(product=random.choice(products), author=fake.name(), rating=random.randint(1, 5), comment=fake.sentence())
            for _ in range(100)
        ]
        db.session.add_all(reviews)
        db.session.commit()

        print('Seeded users, customers, categories, products, orders, inventory, shipments, payments, and reviews.')


if __name__ == '__main__':
    create_schema()
    seed_data()
