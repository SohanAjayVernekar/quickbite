"""Real, orderable dish names grouped by course, one section per cuisine.

Every entry is a dish a customer would genuinely recognise and order. No
dish is invented by appending a preparation style to another dish's name, which
produced implausible names such as "Dal Makhani Bowl · Tandoori".

Each row is (name, rupees, vegetarian). Names here must stay unique within a
cuisine; the catalogue derives the two portion sizes from them.
"""

INDIAN = [
    ('Paneer Tikka Masala', 340, True), ('Chana Masala', 290, True),
    ('Rajma Chawal', 260, True), ('Palak Paneer', 310, True),
    ('Kadai Mushroom', 300, True), ('Malai Kofta', 330, True),
    ('Butter Chicken', 380, False), ('Chicken Chettinad', 390, False),
    ('Lamb Rogan Josh', 460, False), ('Mutton Kadai', 470, False),
    ('Tandoori Chicken', 360, False), ('Chicken 65', 320, False),
    ('Garlic Naan', 110, True), ('Butter Naan', 130, True),
    ('Tandoori Roti', 100, True), ('Laccha Paratha', 120, True),
    ('Vegetable Samosa', 120, True), ('Chicken Samosa', 150, False),
    ('Onion Pakora', 130, True), ('Paneer Tikka', 290, True),
    ('Dal Tadka', 220, True), ('Jeera Rice', 180, True),
    ('Basmati Rice', 200, True), ('Cucumber Salad', 110, True),
    ('Gulab Jamun', 130, True), ('Gajar Halwa', 150, True),
    ('Mango Lassi', 130, True), ('Masala Chai', 90, True),
    ('Hyderabadi Chicken Biryani', 330, False), ('Vegetable Pulao', 220, True),
    ('Paneer Biryani', 350, True), ('Mushroom Biryani', 340, True),
    ('Veg Dum Biryani', 330, True),
]

ITALIAN = [
    ('Margherita Pizza', 340, True), ('Marinara Pizza', 320, True),
    ('Quattro Formaggi Pizza', 480, True), ('Prosciutto Pizza', 460, False),
    ('Diavola Pizza', 470, False), ('Capricciosa Pizza', 450, False),
    ('Funghi Pizza', 440, True), ('Bruschetta', 240, True),
    ('Minestrone Soup', 230, True), ('Arrabbiata Pasta', 380, True),
    ('Carbonara', 430, False), ('Lasagna', 470, False),
    ('Spaghetti Bolognese', 440, False), ('Pesto Pasta', 400, True),
    ('Chicken Parmigiana', 480, False), ('Caesar Salad', 310, True),
    ('Caprese Salad', 300, True), ('Garlic Bread', 180, True),
    ('Tiramisu', 260, True), ('Panna Cotta', 240, True),
    ('Gelato', 190, True), ('Espresso', 130, True),
    ('Aperol Spritz', 320, True), ('House Lemonade', 150, True),
]

BURGERS = [
    ('Classic Cheeseburger', 320, False), ('Bacon Cheeseburger', 420, False),
    ('Double Patty Burger', 480, False), ('Crispy Chicken Burger', 360, False),
    ('Grilled Chicken Burger', 370, False), ('Fish Burger', 380, False),
    ('Paneer Burger', 310, True), ('Mushroom Swiss Burger', 350, True),
    ('Veggie Burger', 300, True), ('Chickpea Burger', 300, True),
    ('Halloumi Burger', 360, True), ('BBQ Bacon Burger', 430, False),
    ('Loaded Fries', 260, True), ('Chilli Cheese Fries', 280, True),
    ('Onion Rings', 220, True), ('Chicken Nuggets', 250, False),
    ('Milkshake', 210, True), ('Lemonade', 150, True),
    ('Chocolate Brownie', 190, True), ('Apple Pie', 200, True),
]

ASIAN = [
    ('Vegetable Hakka Noodles', 300, True), ('Chicken Hakka Noodles', 350, False),
    ('Chilli Garlic Noodles', 320, True), ('Schezwan Noodles', 330, True),
    ('Egg Fried Rice', 280, True), ('Chicken Fried Rice', 320, False),
    ('Burnt Garlic Noodles', 340, True), ('Dan Dan Noodles', 360, False),
    ('Vegetable Spring Rolls', 240, True), ('Chicken Spring Rolls', 280, False),
    ('Wok Tossed Greens', 250, True), ('Stir Fried Broccoli', 260, True),
    ('Chicken Manchurian', 380, False), ('Paneer Manchurian', 340, True),
    ('Sweet Corn Soup', 190, True), ('Hot & Sour Soup', 200, True),
    ('Thai Iced Tea', 170, True), ('Jasmine Tea', 150, True),
    ('Mango Pudding', 200, True), ('Sesame Cookies', 160, True),
]

SOUTH_INDIAN = [
    ('Masala Dosa', 220, True), ('Ghee Dosa', 280, True), ('Podi Dosa', 240, True),
    ('Mysore Masala Dosa', 260, True), ('Rava Dosa', 230, True),
    ('Rava Masala Dosa', 250, True), ('Neer Dosa', 220, True), ('Set Dosa', 210, True),
    ('Ghee Roast Dosa', 270, True), ('Onion Dosa', 230, True), ('Paneer Dosa', 280, True),
    ('Cheese Dosa', 270, True), ('Paper Dosa', 220, True),
    ('Masala Uttapam', 200, True), ('Onion Uttapam', 210, True),
    ('Ghee Podi Idli', 190, True), ('Idli Sambar', 210, True),
    ('Rava Idli', 180, True), ('Medu Vada', 170, True),
    ('Vada Sambar', 200, True), ('Bisi Bele Bath', 240, True),
    ('Curd Rice', 170, True), ('Lemon Rice', 180, True),
    ('Tomato Rice', 180, True), ('Coconut Chutney', 90, True),
    ('Sambar', 160, True), ('Filter Coffee', 120, True),
    ('Mango Shrikhand', 170, True), ('Badam Milk', 150, True),
    ('Banana Leaf Curry', 260, True), ('Rasam', 130, True),
]

MEXICAN = [
    ('Veggie Tacos', 290, True), ('Chicken Tacos', 340, False),
    ('Fish Tacos', 390, False), ('Beef Tacos', 370, False),
    ('Shrimp Tacos', 420, False), ('Barbacoa Tacos', 380, False),
    ('Al Pastor Tacos', 350, False), ('Street Corn Tacos', 320, True),
    ('Chicken Burrito', 380, False), ('Veggie Burrito', 340, True),
    ('Bean Quesadilla', 330, True), ('Chicken Quesadilla', 370, False),
    ('Loaded Nachos', 320, True),
    ('Chilli Con Carne', 330, False), ('Black Bean Bowl', 300, True),
    ('Guacamole & Chips', 280, True), ('Salsa & Corn Chips', 220, True),
    ('Elote Corn', 210, True), ('Churros', 240, True),
    ('Flan', 200, True), ('Choco Flan', 220, True),
    ('Mango Margarita', 300, True), ('Horchata', 190, True),
]

JAPANESE = [
    ('Vegetable Maki', 320, True), ('Cucumber Maki', 300, True),
    ('Avocado Cucumber Maki', 320, True), ('Salmon Sushi Roll', 420, False),
    ('Chicken Katsu Roll', 420, False), ('Spicy Tuna Roll', 460, False),
    ('Salmon Nigiri', 480, False), ('Tuna Nigiri', 460, False),
    ('Chicken Yakitori', 380, False), ('Vegetable Tempura', 340, True),
    ('Chicken Karaage', 400, False), ('Edamame', 230, True),
    ('Miso Soup', 200, True), ('Chicken Ramen', 420, False),
    ('Vegetable Ramen', 390, True), ('Tonkotsu Ramen', 450, False),
    ('Gyoza', 330, False), ('Vegetable Gyoza', 300, True),
    ('Teriyaki Rice Bowl', 380, False), ('Sushi Platter', 480, False),
    ('Veggie Sushi Platter', 440, True), ('Green Tea', 140, True),
    ('Mochi Ice Cream', 220, True), ('Matcha Cheesecake', 280, True),
]

THAI = [
    ('Vegetable Pad Thai', 340, True), ('Chicken Pad Thai', 380, False),
    ('Beef Pad Thai', 400, False), ('Prawn Pad Thai', 430, False),
    ('Tom Kha Soup', 280, False), ('Tom Yum Soup', 290, False),
    ('Green Curry', 360, False), ('Red Curry', 370, False),
    ('Thai Basil Chicken', 390, False), ('Pad See Ew', 380, False),
    ('Papaya Salad', 250, False), ('Som Tam', 240, False),
    ('Spring Rolls', 260, True), ('Chicken Satay', 350, False),
    ('Pineapple Fried Rice', 330, True), ('Mango Sticky Rice', 250, True),
    ('Thai Iced Tea', 180, True), ('Thai Lemonade', 160, True),
    ('Coconut Rice', 240, True), ('Banana Pudding', 220, True),
    ('Chrysanthemum Tea', 140, True),
]

KOREAN = [
    ('Kimchi Fried Rice', 320, True), ('Chicken Bibimbap', 400, False),
    ('Vegetable Bibimbap', 370, True), ('Beef Bulgogi', 430, False),
    ('Chicken Bulgogi', 400, False), ('Korean Fried Chicken', 420, False),
    ('Tteokbokki', 340, True), ('Spicy Tteokbokki', 360, True),
    ('Mandu Dumplings', 330, False), ('Vegetable Mandu', 300, True),
    ('Kimchi Dumplings', 320, True), ('Japchae', 350, False),
    ('Korean Corn Dog', 250, True), ('Seafood Pancake', 390, False),
    ('Veggie Pancake', 340, True), ('Kimchi', 180, True),
    ('Barley Tea', 150, True), ('Korean Coffee', 170, True),
    ('Tteok', 200, True), ('Hotteok', 190, True),
    ('Bingsu', 260, True), ('Rice Cake Skewer', 180, True),
]

MEDITERRANEAN = [
    ('Chicken Souvlaki', 420, False), ('Pita Gyros', 390, False),
    ('Spanakopita', 340, True), ('Moussaka', 400, True),
    ('Greek Salad', 300, True), ('Tzatziki', 220, True),
    ('Hummus', 260, True), ('Baba Ganoush', 280, True),
    ('Stuffed Vine Leaves', 300, True), ('Falafel Wrap', 330, True),
    ('Chicken Shawarma', 390, False), ('Lamb Shawarma', 430, False),
    ('Fattoush Salad', 310, True), ('Tabbouleh', 270, True),
    ('Grilled Halloumi', 360, True), ('Chicken Kofta', 400, False),
    ('Pita Bread', 130, True), ('Olive Oil Cake', 280, True),
    ('Baklava', 240, True), ('Lemonade', 170, True),
    ('Greek Coffee', 160, True), ('Mint Tea', 150, True),
]

LEBANESE = [
    ('Chicken Shawarma Plate', 410, False), ('Lamb Shawarma Plate', 440, False),
    ('Falafel Wrap', 330, True), ('Hummus Plate', 290, True),
    ('Muhammara', 280, True), ('Baba Ghanoush', 290, True),
    ('Kebbeh', 360, False), ('Kibbeh Nayyeh', 380, False),
    ('Tabbouleh', 280, True), ('Fattoush', 320, True),
    ('Chicken Taouk', 430, False), ('Grilled Vegetables', 290, True),
    ('Lentil Soup', 220, True), ('Foul Medames', 240, True),
    ('Manakish', 210, True), ('Spinach Fatayer', 220, True),
    ('Pita Bread', 130, True), ('Zaatar Bread', 150, True),
    ('Baklava', 250, True), ('Knafeh', 280, True),
    ('Mint Lemonade', 180, True), ('Arabic Coffee', 170, True),
]

HEALTHY = [
    ('Quinoa Bowl', 330, True), ('Avocado Salad', 340, True),
    ('Grilled Chicken Salad', 390, False), ('Tofu Salad', 320, True),
    ('Chickpea Bowl', 310, True), ('Sweet Potato Bowl', 300, True),
    ('Paneer Tikka Salad', 360, True), ('Chicken Poke Bowl', 420, False),
    ('Vegetable Soup', 220, True), ('Tomato Shorba', 230, True),
    ('Green Smoothie', 250, True), ('Fruit Salad', 210, True),
    ('Hummus & Veg Wrap', 310, True), ('Chicken Wrap', 380, False),
    ('Lentil Salad', 280, True), ('Brown Rice Bowl', 320, True),
    ('Steamed Vegetables', 240, True), ('Boiled Eggs', 160, True),
    ('Oats Porridge', 190, True), ('Greek Yoghurt', 170, True),
    ('Protein Shake', 260, True), ('Coconut Water', 150, True),
]

DESSERTS = [
    ('Gulab Jamun', 150, True), ('Gajar Ka Halwa', 170, True),
    ('Rasmalai', 180, True), ('Kheer', 160, True),
    ('Mango Kulfi', 150, True), ('Falooda', 190, True),
    ('Chocolate Brownie', 210, True), ('Chocolate Lava Cake', 240, True),
    ('New York Cheesecake', 280, True), ('Blueberry Cheesecake', 290, True),
    ('Tiramisu', 270, True), ('Panna Cotta', 250, True),
    ('Strawberry Shortcake', 260, True), ('Carrot Cake', 250, True),
    ('Vanilla Ice Cream', 170, True), ('Chocolate Sundae', 220, True),
    ('Waffle with Cream', 240, True), ('Pancake Stack', 260, True),
    ('Apple Pie', 230, True), ('Bread Pudding', 240, True),
    ('Fresh Fruit Platter', 280, True), ('Lemon Tart', 250, True),
]

BAKERY = [
    ('Butter Croissant', 160, True), ('Pain au Chocolat', 190, True),
    ('Almond Croissant', 210, True), ('Blueberry Muffin', 150, True),
    ('Chocolate Muffin', 150, True), ('Banana Bread', 170, True),
    ('Chocolate Chip Cookie', 120, True), ('Double Chocolate Cookie', 140, True),
    ('Brownies', 190, True), ('Banana Walnut Loaf', 200, True),
    ('Garlic Bread', 160, True), ('Cheese Toastie', 240, True),
    ('Vegetable Puff', 180, True), ('Chicken Puff', 220, False),
    ('Samosa', 130, True), ('Vegetable Roll', 160, True),
    ('Chicken Roll', 200, False), ('Rusk Toast', 120, True),
    ('Egg Mayo Sandwich', 190, True), ('Chicken Sandwich', 230, False),
    ('Cappuccino', 180, True), ('Hot Chocolate', 170, True),
]

BREAKFAST = [
    ('Avocado Toast', 290, True),
    ('Pancake Stack', 270, True), ('Blueberry Pancakes', 300, True),
    ('Scrambled Eggs', 240, True), ('Egg Omelette', 250, True),
    ('Bacon & Eggs', 320, False), ('Sausage & Eggs', 330, False),
    ('Full English Breakfast', 480, False), ('Fried Eggs on Toast', 280, True),
    ('French Toast', 270, True), ('Belgian Waffles', 320, True),
    ('Hash Brown', 180, True), ('Breakfast Bowl', 300, True),
    ('Masala Omelette', 260, True), ('Cheese Omelette', 280, True),
    ('Avocado Toastie', 310, True), ('Egg Bhurji', 280, True),
    ('Granola & Yoghurt', 290, True), ('Seasonal Fruit Bowl', 240, True),
    ('Filter Coffee', 120, True), ('Masala Chai', 100, True),
]

STREET_FOOD = [
    ('Vegetable Samosa', 130, True), ('Chicken Samosa', 160, False),
    ('Paneer Tikka Chaat', 260, True), ('Aloo Tikki Chaat', 230, True),
    ('Dahi Puri', 240, True), ('Bhel Puri', 220, True),
    ('Papdi Chaat', 250, True), ('Golgappa', 180, True),
    ('Pani Puri', 200, True), ('Aloo Chaat', 220, True),
    ('Chana Chaat', 240, True), ('Fruit Chaat', 200, True),
    ('Corn Chaat', 210, True),
    ('Kulcha Chaat', 260, True), ('Dabeli', 180, True),
    ('Pani Puri Plate', 280, True), ('Chaat Platter', 480, True),
    ('Kathi Roll', 220, False), ('Veg Kathi Roll', 200, True),
    ('Masala Chaat', 250, True), ('Masala Soda', 120, True),
]

SEAFOOD = [
    ('Grilled Salmon', 440, False), ('Fish Curry', 460, False),
    ('Butter Fish', 420, False), ('Prawn Curry', 420, False),
    ('Fish Biryani', 480, False), ('Prawn Biryani', 420, False),
    ('Fish Tikka', 400, False), ('Prawn Tikka', 440, False),
    ('Crab Curry', 480, False), ('Squid Masala', 440, False),
    ('Fried Fish', 480, False), ('Fish Chips', 420, False),
    ('Tuna Sandwich', 380, False), ('Seafood Soup', 420, False),
    ('Clam Chowder', 460, False), ('Grilled Prawns', 480, False),
    ('Fish Wrap', 400, False), ('Calamari Rings', 440, False),
    ('Lemon Fish', 500, False), ('Garlic Prawns', 460, False),
    ('Seafood Platter', 480, False), ('Lime Soda', 150, True),
]

BBQ = [
    ('Chicken Tikka', 380, False), ('Seekh Kebab', 420, False),
    ('Paneer Tikka', 340, True), ('Malai Kebab', 440, False),
    ('Chicken Seekh Kebab', 430, False), ('Galouti Kebab', 420, False),
    ('Tandoori Chicken', 400, False), ('Mutton Seekh', 480, False),
    ('Grilled Fish', 440, False), ('Tandoori Paneer Platter', 420, True),
    ('Chicken Platter', 480, False), ('Mixed Grill Platter', 480, False),
    ('Grilled Corn', 180, True), ('Garlic Bread', 170, True),
    ('Mint Chutney', 90, True), ('Onion Salad', 110, True),
    ('Masala Fries', 200, True), ('BBQ Chicken Wings', 420, False),
    ('Paneer Tikka Plate', 380, True), ('Kebabs with Naan', 440, False),
    ('Kulfi', 150, True), ('Masala Chai', 90, True),
]

BEVERAGES = [
    ('Masala Chai', 90, True), ('Filter Coffee', 120, True),
    ('Cold Brew Coffee', 180, True), ('Iced Coffee', 190, True),
    ('Mango Lassi', 140, True), ('Sweet Lassi', 140, True),
    ('Salted Lassi', 150, True), ('Fresh Lime Soda', 130, True),
    ('Lemonade', 150, True), ('Masala Soda', 120, True),
    ('Mojito', 220, True), ('Fresh Lime Cooler', 160, True),
    ('Watermelon Juice', 170, True), ('Orange Juice', 160, True),
    ('Apple Juice', 160, True), ('Pineapple Juice', 170, True),
    ('Green Tea', 110, True), ('Black Tea', 100, True),
    ('Hot Chocolate', 170, True), ('Milkshake', 210, True),
    ('Oreo Milkshake', 240, True), ('Strawberry Milkshake', 230, True),
]

BENGALI = [
    ('Kosha Mangsho', 460, False), ('Chicken Curry', 400, False),
    ('Ilish Bhapa', 480, False), ('Prawn Curry', 440, False),
    ('Luchi', 180, True), ('Puchka', 200, True),
    ('Dahi Vada', 170, True), ('Cholar Dal', 240, True),
    ('Vegetable Jhinge', 220, True), ('Bori Begun', 260, True),
    ('Shukto', 240, True), ('Aloo Chachar', 200, True),
    ('Fish Curry', 460, False), ('Cholar Dal Rice', 260, True),
    ('Mishti Doi', 140, True), ('Sandesh', 160, True),
    ('Rasgulla', 150, True), ('Chai', 80, True),
]

CUISINE_MENUS = {
    'Indian': INDIAN, 'Italian': ITALIAN, 'Burgers': BURGERS, 'Asian': ASIAN,
    'South Indian': SOUTH_INDIAN, 'Mexican': MEXICAN, 'Japanese': JAPANESE,
    'Thai': THAI, 'Korean': KOREAN, 'Mediterranean': MEDITERRANEAN,
    'Lebanese': LEBANESE, 'Healthy': HEALTHY, 'Desserts': DESSERTS,
    'Bakery': BAKERY, 'Breakfast': BREAKFAST, 'Street Food': STREET_FOOD,
    'Seafood': SEAFOOD, 'BBQ': BBQ, 'Beverages': BEVERAGES, 'Bengali': BENGALI,
}
