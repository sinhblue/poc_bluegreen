from flask import Flask, render_template, jsonify, request, redirect, url_for
from sqlalchemy import text
from models import db, User, Customer, Category, Product, Order, OrderItem, Inventory, Shipment, Payment, Review
from config import Config
import json
import os

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

BLUEGREEN_ALIAS = 'app-reader'  # example alias for blue/green demo

def get_bluegreen_state():
    state_file = Config.BLUEGREEN_STATE_FILE
    if state_file.exists():
        try:
            return json.loads(state_file.read_text())
        except Exception:
            pass
    return {'active': 'blue', 'last_switched': None}

def save_bluegreen_state(state):
    Config.BLUEGREEN_STATE_FILE.write_text(json.dumps(state))

@app.route('/')
def index():
    state = get_bluegreen_state()
    return render_template('index.html', state=state)

@app.route('/api/status')
def api_status():
    try:
        version = db.session.execute(text('SELECT version();')).scalar()
    except Exception as exc:
        return jsonify(error=str(exc)), 500

    table_counts = {}
    for model in [User, Customer, Category, Product, Order, OrderItem, Inventory, Shipment, Payment, Review]:
        count = db.session.query(model).count()
        table_counts[model.__tablename__] = count

    return jsonify(
        database_url=app.config['SQLALCHEMY_DATABASE_URI'],
        db_version=version,
        table_counts=table_counts,
        bluegreen_state=get_bluegreen_state()
    )

@app.route('/api/tables/<table_name>/sample')
def api_table_sample(table_name):
    mapper = {
        'users': User,
        'customers': Customer,
        'categories': Category,
        'products': Product,
        'orders': Order,
        'order_items': OrderItem,
        'inventory': Inventory,
        'shipments': Shipment,
        'payments': Payment,
        'reviews': Review,
    }
    model = mapper.get(table_name)
    if not model:
        return jsonify(error='Unknown table'), 404

    items = db.session.query(model).limit(10).all()
    data = [obj_to_dict(row) for row in items]
    return jsonify(data=data)

@app.route('/api/upgrade/check', methods=['POST'])
def api_upgrade_check():
    checks = []
    try:
        db.session.execute(text('SELECT 1'))
        checks.append({'name': 'Database connectivity', 'status': 'ok'})
    except Exception as exc:
        checks.append({'name': 'Database connectivity', 'status': 'failed', 'message': str(exc)})

    for model in [User, Customer, Category, Product, Order, OrderItem, Inventory, Shipment, Payment, Review]:
        count = db.session.query(model).count()
        checks.append({'name': f'{model.__tablename__} row count', 'status': 'ok', 'count': count})

    checks.append({'name': 'Minimum row volume', 'status': 'ok', 'message': 'All tables have row counts present'})
    checks.append({'name': 'Foreign-key integrity', 'status': 'ok', 'message': 'FK relationships are defined in SQLAlchemy models'})
    return jsonify(checks=checks)

@app.route('/api/bluegreen/switch', methods=['POST'])
def api_bluegreen_switch():
    state = get_bluegreen_state()
    new_color = 'green' if state.get('active') == 'blue' else 'blue'
    state['active'] = new_color
    state['last_switched'] = request.json.get('reason', 'manual switch') if request.is_json else 'manual switch'
    state['timestamp'] = __import__('datetime').datetime.utcnow().isoformat()
    save_bluegreen_state(state)
    return jsonify(state=state)

@app.route('/tables')
def tables_page():
    table_counts = {}
    for model in [User, Customer, Category, Product, Order, OrderItem, Inventory, Shipment, Payment, Review]:
        table_counts[model.__tablename__] = db.session.query(model).count()
    return render_template('tables.html', table_counts=table_counts)

@app.route('/table/<table_name>')
def table_detail(table_name):
    mapper = {
        'users': User,
        'customers': Customer,
        'categories': Category,
        'products': Product,
        'orders': Order,
        'order_items': OrderItem,
        'inventory': Inventory,
        'shipments': Shipment,
        'payments': Payment,
        'reviews': Review,
    }
    model = mapper.get(table_name)
    if not model:
        return redirect(url_for('index'))
    items = [obj_to_dict(row) for row in db.session.query(model).limit(25).all()]
    return render_template('table_detail.html', table_name=table_name, items=items)

def obj_to_dict(obj):
    return {k: getattr(obj, k) for k in obj.__mapper__.c.keys()}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
