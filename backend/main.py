from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory data storage
cars = [
    {"id": 1, "make": "Toyota", "model": "Camry", "year": 2020, "color": "Blue", "price": 25000},
    {"id": 2, "make": "Honda", "model": "Civic", "year": 2019, "color": "Red", "price": 22000},
    {"id": 3, "make": "Ford", "model": "Mustang", "year": 2021, "color": "Black", "price": 35000}
]

@app.route('/')
def home():
    return "Welcome to the Car Dealership API!"

@app.route('/cars', methods=['GET'])
def get_cars():
    return jsonify(cars)

@app.route('/cars/<int:car_id>', methods=['GET'])
def get_car(car_id):
    car = next((car for car in cars if car["id"] == car_id), None)
    if car is None:
        return jsonify({"error": "Car not found"}), 404
    return jsonify(car)

@app.route('/cars', methods=['POST'])
def add_car():
    data = request.get_json()
    required_fields = ['make', 'model', 'year', 'color', 'price']
    
    if not data or not all(field in data for field in required_fields):
        return jsonify({"error": "All fields required: make, model, year, color, price"}), 400
    
    new_car = {
        "id": len(cars) + 1,
        "make": data['make'],
        "model": data['model'],
        "year": data['year'],
        "color": data['color'],
        "price": data['price']
    }
    cars.append(new_car)
    return jsonify(new_car), 201

@app.route('/cars/<int:car_id>', methods=['PUT'])
def update_car(car_id):
    car = next((car for car in cars if car["id"] == car_id), None)
    if car is None:
        return jsonify({"error": "Car not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    car['make'] = data.get('make', car['make'])
    car['model'] = data.get('model', car['model'])
    car['year'] = data.get('year', car['year'])
    car['color'] = data.get('color', car['color'])
    car['price'] = data.get('price', car['price'])
    return jsonify(car)

@app.route('/cars/<int:car_id>', methods=['DELETE'])
def delete_car(car_id):
    global cars
    cars = [car for car in cars if car["id"] != car_id]
    return jsonify({"message": "Car deleted successfully"})

@app.route('/cars/search', methods=['GET'])
def search_cars():
    make = request.args.get('make')
    model = request.args.get('model')
    min_price = request.args.get('min_price', type=int)
    max_price = request.args.get('max_price', type=int)
    
    filtered_cars = cars
    
    if make:
        filtered_cars = [car for car in filtered_cars if car['make'].lower() == make.lower()]
    if model:
        filtered_cars = [car for car in filtered_cars if car['model'].lower() == model.lower()]
    if min_price:
        filtered_cars = [car for car in filtered_cars if car['price'] >= min_price]
    if max_price:
        filtered_cars = [car for car in filtered_cars if car['price'] <= max_price]
    
    return jsonify(filtered_cars)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6000)