import 'food_photos_generated.dart';

/// One bundled image for each distinct recipe name. Identical recipes in
/// other kitchens and their regular/sharing portions keep the same artwork.
class FoodPhotos {
  static const byDish = <String, String>{
  "Paneer Dum Biryani": "dish-paneer-dum-biryani.jpg",
  "Butter Chicken & Rice": "dish-butter-chicken-rice.jpg",
  "Dal Makhani Bowl": "dish-dal-makhani-bowl.jpg",
  "Chole & Jeera Rice": "dish-chole-jeera-rice.jpg",
  "Vegetable Pulao": "dish-vegetable-pulao.jpg",
  "Hyderabadi Chicken Biryani": "dish-hyderabadi-chicken-biryani.jpg",
  "Classic Margherita": "dish-classic-margherita.jpg",
  "Roasted Vegetable Pizza": "dish-roasted-vegetable-pizza.jpg",
  "Chicken Pesto Pizza": "dish-chicken-pesto-pizza.jpg",
  "Four Cheese Pizza": "dish-four-cheese-pizza.jpg",
  "Mushroom Truffle Pizza": "dish-mushroom-truffle-pizza.jpg",
  "Spicy Corn Pizza": "dish-spicy-corn-pizza.jpg",
  "Crispy Paneer Burger": "dish-crispy-paneer-burger.jpg",
  "Smoky Garden Burger": "dish-smoky-garden-burger.jpg",
  "Double Cheese Chicken Burger": "dish-double-cheese-chicken-burger.jpg",
  "Mushroom Swiss Burger": "dish-mushroom-swiss-burger.jpg",
  "Spicy Chickpea Burger": "dish-spicy-chickpea-burger.jpg",
  "BBQ Chicken Burger": "dish-bbq-chicken-burger.jpg",
  "Sesame Vegetable Noodles": "dish-sesame-vegetable-noodles.jpg",
  "Chilli Garlic Noodles": "dish-chilli-garlic-noodles.jpg",
  "Chicken Hakka Noodles": "dish-chicken-hakka-noodles.jpg",
  "Mushroom Noodle Bowl": "dish-mushroom-noodle-bowl.jpg",
  "Schezwan Tofu Noodles": "dish-schezwan-tofu-noodles.jpg",
  "Prawn Pepper Noodles": "dish-prawn-pepper-noodles.jpg",
  "Masala Dosa": "dish-masala-dosa.jpg",
  "Ghee Podi Idli": "dish-ghee-podi-idli.jpg",
  "Onion Uttapam": "dish-onion-uttapam.jpg",
  "Medu Vada": "dish-medu-vada.jpg",
  "Mysore Masala Dosa": "dish-mysore-masala-dosa.jpg",
  "Egg Dosa": "dish-egg-dosa.jpg",
  "Black Bean Tacos": "dish-black-bean-tacos.jpg",
  "Chicken Burrito": "dish-chicken-burrito.jpg",
  "Corn Quesadilla": "dish-corn-quesadilla.jpg",
  "Chipotle Paneer Bowl": "dish-chipotle-paneer-bowl.jpg",
  "Loaded Nachos": "dish-loaded-nachos.jpg",
  "Fish Tacos": "dish-fish-tacos.jpg",
  "Avocado Cucumber Maki": "dish-avocado-cucumber-maki.jpg",
  "Salmon Sushi Roll": "dish-salmon-sushi-roll.jpg",
  "Tofu Teriyaki Bowl": "dish-tofu-teriyaki-bowl.jpg",
  "Chicken Katsu Bowl": "dish-chicken-katsu-bowl.jpg",
  "Vegetable Gyoza": "dish-vegetable-gyoza.jpg",
  "Mushroom Miso Ramen": "dish-mushroom-miso-ramen.jpg",
  "Tofu Green Curry": "dish-tofu-green-curry.jpg",
  "Chicken Red Curry": "dish-chicken-red-curry.jpg",
  "Vegetable Pad Thai": "dish-vegetable-pad-thai.jpg",
  "Basil Chicken Rice": "dish-basil-chicken-rice.jpg",
  "Tom Kha Mushroom Soup": "dish-tom-kha-mushroom-soup.jpg",
  "Mango Sticky Rice": "dish-mango-sticky-rice.jpg",
  "Tofu Bibimbap": "dish-tofu-bibimbap.jpg",
  "Korean Fried Chicken": "dish-korean-fried-chicken.jpg",
  "Vegetable Japchae": "dish-vegetable-japchae.jpg",
  "Mushroom Bulgogi Bowl": "dish-mushroom-bulgogi-bowl.jpg",
  "Kimchi Rice": "dish-kimchi-rice.jpg",
  "Chicken Mandu": "dish-chicken-mandu.jpg",
  "Falafel Pita": "dish-falafel-pita.jpg",
  "Greek Salad": "dish-greek-salad.jpg",
  "Grilled Chicken Plate": "dish-grilled-chicken-plate.jpg",
  "Roasted Vegetable Couscous": "dish-roasted-vegetable-couscous.jpg",
  "Hummus Mezze": "dish-hummus-mezze.jpg",
  "Halloumi Wrap": "dish-halloumi-wrap.jpg",
  "Falafel Shawarma": "dish-falafel-shawarma.jpg",
  "Chicken Shawarma": "dish-chicken-shawarma.jpg",
  "Hummus & Pita": "dish-hummus-pita.jpg",
  "Baba Ganoush": "dish-baba-ganoush.jpg",
  "Tabbouleh Bowl": "dish-tabbouleh-bowl.jpg",
  "Lamb Kofta Plate": "dish-lamb-kofta-plate.jpg",
  "Rainbow Quinoa Bowl": "dish-rainbow-quinoa-bowl.jpg",
  "Grilled Chicken Salad": "dish-grilled-chicken-salad.jpg",
  "Avocado Toast": "dish-avocado-toast.jpg",
  "Tofu Protein Bowl": "dish-tofu-protein-bowl.jpg",
  "Beetroot Hummus Bowl": "dish-beetroot-hummus-bowl.jpg",
  "Roasted Pumpkin Salad": "dish-roasted-pumpkin-salad.jpg",
  "Chocolate Brownie": "dish-chocolate-brownie.jpg",
  "Strawberry Cheesecake": "dish-strawberry-cheesecake.jpg",
  "Gulab Jamun": "dish-gulab-jamun.jpg",
  "Mango Sundae": "dish-mango-sundae.jpg",
  "Chocolate Lava Cake": "dish-chocolate-lava-cake.jpg",
  "Pistachio Kulfi": "dish-pistachio-kulfi.jpg",
  "Butter Croissant": "dish-butter-croissant.jpg",
  "Chocolate Croissant": "dish-chocolate-croissant.jpg",
  "Cinnamon Roll": "dish-cinnamon-roll.jpg",
  "Garlic Focaccia": "dish-garlic-focaccia.jpg",
  "Banana Walnut Loaf": "dish-banana-walnut-loaf.jpg",
  "Mushroom Puff": "dish-mushroom-puff.jpg",
  "Berry Pancakes": "dish-berry-pancakes.jpg",
  "Masala Omelette Toast": "dish-masala-omelette-toast.jpg",
  "Peanut Butter Oats": "dish-peanut-butter-oats.jpg",
  "Poha Bowl": "dish-poha-bowl.jpg",
  "Waffle & Banana": "dish-waffle-banana.jpg",
  "Egg Breakfast Sandwich": "dish-egg-breakfast-sandwich.jpg",
  "Pani Puri Kit": "dish-pani-puri-kit.jpg",
  "Pav Bhaji": "dish-pav-bhaji.jpg",
  "Samosa Chaat": "dish-samosa-chaat.jpg",
  "Dahi Puri": "dish-dahi-puri.jpg",
  "Paneer Kathi Roll": "dish-paneer-kathi-roll.jpg",
  "Chicken Kathi Roll": "dish-chicken-kathi-roll.jpg",
  "Crispy Fish & Chips": "dish-crispy-fish-chips.jpg",
  "Garlic Butter Prawns": "dish-garlic-butter-prawns.jpg",
  "Goan Fish Curry": "dish-goan-fish-curry.jpg",
  "Pepper Squid": "dish-pepper-squid.jpg",
  "Prawn Fried Rice": "dish-prawn-fried-rice.jpg",
  "Coastal Tofu Curry": "dish-coastal-tofu-curry.jpg",
  "Tandoori Paneer Skewers": "dish-tandoori-paneer-skewers.jpg",
  "Smoked Chicken Wings": "dish-smoked-chicken-wings.jpg",
  "Charred Mushroom Skewers": "dish-charred-mushroom-skewers.jpg",
  "Chicken Tikka Plate": "dish-chicken-tikka-plate.jpg",
  "BBQ Corn Ribs": "dish-bbq-corn-ribs.jpg",
  "Lamb Seekh Kebab": "dish-lamb-seekh-kebab.jpg",
  "Iced Vanilla Latte": "dish-iced-vanilla-latte.jpg",
  "Mango Lassi": "dish-mango-lassi.jpg",
  "Cold Brew Coffee": "dish-cold-brew-coffee.jpg",
  "Strawberry Milkshake": "dish-strawberry-milkshake.jpg",
  "Mint Lime Cooler": "dish-mint-lime-cooler.jpg",
  "Chocolate Frappe": "dish-chocolate-frappe.jpg",
  "Kolkata Chicken Biryani": "dish-kolkata-chicken-biryani.jpg",
  "Luchi & Aloo Dum": "dish-luchi-aloo-dum.jpg",
  "Cholar Dal & Rice": "dish-cholar-dal-rice.jpg",
  "Shorshe Fish": "dish-shorshe-fish.jpg",
  "Vegetable Chop": "dish-vegetable-chop.jpg",
  "Mishti Doi": "dish-mishti-doi.jpg",
  "Garden Vegetable Biryani": "dish-garden-vegetable-biryani.jpg",
  "Saffron Rice Bowl": "dish-saffron-rice-bowl.jpg",
  "Family Paneer Biryani": "dish-family-paneer-biryani.jpg",
  "Basil & Mozzarella Pizza": "dish-basil-mozzarella-pizza.jpg",
  "Double Cheese Paneer Burger": "dish-double-cheese-paneer-burger.jpg",
  "Paneer Burger & Fries": "dish-paneer-burger-fries.jpg",
  "Noodles & Dumplings": "dish-noodles-dumplings.jpg",
  "Charred Paneer Rice Bowl": "dish-charred-paneer-rice-bowl.jpg",
  "Mint & Saffron Bowl": "dish-mint-saffron-bowl.jpg",
  "Biryani Feast for Two": "dish-biryani-feast-for-two.jpg",
  "Seasonal Rice Special": "dish-seasonal-rice-special.jpg",
  "Rustic Tomato Pizza": "dish-rustic-tomato-pizza.jpg",
  "Basil Garden Pizza": "dish-basil-garden-pizza.jpg",
  "Mozzarella Sourdough Pizza": "dish-mozzarella-sourdough-pizza.jpg",
  "Large Margherita": "dish-large-margherita.jpg"
};

  static const byCuisine = <String, String>{
  "Indian": "dish-paneer-dum-biryani.jpg",
  "Italian": "dish-classic-margherita.jpg",
  "Burgers": "dish-crispy-paneer-burger.jpg",
  "Asian": "dish-sesame-vegetable-noodles.jpg",
  "South Indian": "dish-masala-dosa.jpg",
  "Mexican": "dish-black-bean-tacos.jpg",
  "Japanese": "dish-avocado-cucumber-maki.jpg",
  "Thai": "dish-tofu-green-curry.jpg",
  "Korean": "dish-tofu-bibimbap.jpg",
  "Mediterranean": "dish-falafel-pita.jpg",
  "Lebanese": "dish-falafel-shawarma.jpg",
  "Healthy": "dish-rainbow-quinoa-bowl.jpg",
  "Desserts": "dish-chocolate-brownie.jpg",
  "Bakery": "dish-butter-croissant.jpg",
  "Breakfast": "dish-berry-pancakes.jpg",
  "Street Food": "dish-pani-puri-kit.jpg",
  "Seafood": "dish-crispy-fish-chips.jpg",
  "BBQ": "dish-tandoori-paneer-skewers.jpg",
  "Beverages": "dish-iced-vanilla-latte.jpg",
  "Bengali": "dish-kolkata-chicken-biryani.jpg"
};

  /// One deterministic illustration per exact product name, including named
  /// portion variants. This is used when a product has no curated photo.
  static const generatedByDish = GeneratedFoodPhotos.byDish;

  static const legacyImages = <String, String>{
  "emoji:🥞": "food-south-indian.png",
  "emoji:🌮": "photo-tacos.jpg",
  "emoji:🍣": "photo-sushi.jpg",
  "emoji:🍜": "food-thai-curry.png",
  "emoji:🍲": "food-korean-bowl.png",
  "emoji:🥙": "photo-rainbow-salad.jpg",
  "emoji:🧆": "photo-falafel.jpg",
  "emoji:🥗": "photo-salad.jpg",
  "emoji:🍰": "photo-berry-cake.jpg",
  "emoji:🥐": "photo-croissant.jpg",
  "emoji:🧇": "photo-pancakes.jpg",
  "emoji:🥟": "food-indian-chaat.png",
  "emoji:🍤": "food-coastal-fish.png",
  "emoji:🍢": "photo-chicken-skewers.jpg",
  "emoji:🧋": "photo-strawberry-shake.jpg",
  "emoji:🍛": "food-indian-sweets.png"
};

  static const credits = <String, Map<String, String>>{
  "photo-dosa.jpg": {
    "title": "Dosa · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/id/s/foto/masala-dosa",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-sushi.jpg": {
    "title": "Sushi · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/sushi-on-plate-7BQC4h7wd9Y",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-maki.jpg": {
    "title": "Maki · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E9%BB%92%E3%81%84%E5%9B%9B%E8%A7%92%E3%81%84%E7%9A%BF%E3%81%AB%E5%AF%BF%E5%8F%B8-Dbx6-XZY6Dg",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-salmon.jpg": {
    "title": "Salmon · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E9%BB%92%E3%81%84%E9%99%B6%E5%99%A8%E3%81%AE%E7%9A%BF%E3%81%AB%E5%AF%BF%E5%8F%B8-IFvjRdXhj_U",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-tacos.jpg": {
    "title": "Tacos · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E6%98%BC%E9%96%93%E3%81%AE%E9%A3%9F%E5%8D%93%E4%B8%8A%E3%81%AE%E6%96%99%E7%90%86%E3%81%AE%E3%82%BB%E3%83%AC%E3%82%AF%E3%83%86%E3%82%A3%E3%83%96%E3%83%95%E3%82%A9%E3%83%BC%E3%82%AB%E3%82%B9%E6%92%AE%E5%BD%B1-_yWhM5TZgdo",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-mexican.jpg": {
    "title": "Mexican · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-table-topped-with-plates-of-food-and-condiments-y5fJm1HjfBE",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-ramen.jpg": {
    "title": "Ramen · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-person-holding-chopsticks-over-a-bowl-of-noodles-A77HbsdWHU8",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-croissant.jpg": {
    "title": "Croissant · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/es/fotos/los-croissants-recien-horneados-se-colocan-en-una-bandeja-7Yl_Qhxfgok",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-pastry.jpg": {
    "title": "Pastry · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/s/photos/butter-croissant",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-kebab.jpg": {
    "title": "Kebab · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/fr/photos/viande-grillee-sur-un-gril-au-charbon-de-bois-uIiMSu88RZQ",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-chicken-skewers.jpg": {
    "title": "Chicken Skewers · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/s/photos/chicken-kebab",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-grill.jpg": {
    "title": "Grill · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/s/photos/kabob",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-lassi.jpg": {
    "title": "Lassi · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/s/photos/mango-lassi",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-avocado-toast.jpg": {
    "title": "Avocado Toast · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/sliced-bread-with-green-vegetable-and-sliced-lemon-on-white-ceramic-plate-T72IMiUvP4w",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-falafel.jpg": {
    "title": "Falafel · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/two-plates-of-food-with-lettuce-and-tomatoes-SzJo-8Q5iD4",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-salad.jpg": {
    "title": "Salad · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/vegetable-salad-pCxJvSeSB5A",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-green-salad.jpg": {
    "title": "Green Salad · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/vegetable-salad-on-white-ceramic-bowl-gOJxrVvhCF8",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-rainbow-salad.jpg": {
    "title": "Rainbow Salad · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-yellow-plate-topped-with-a-colorful-salad-io1Rrd-1Cr0",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-cheesecake.jpg": {
    "title": "Cheesecake · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-piece-of-cheesecake-with-a-strawberry-on-top-66JUvjOHHRw",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-berry-cake.jpg": {
    "title": "Berry Cake · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-cheesecake-topped-with-berries-and-blueberries-on-a-plate-MBTbpWhycOQ",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-pancakes.jpg": {
    "title": "Pancakes · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-stack-of-pancakes-covered-in-blueberries-and-syrup-krqTbKwuFgw",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-coffee.jpg": {
    "title": "Coffee · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/it/foto/tazza-in-ceramica-bianca-con-caffe-Zgq3cqztoLI",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-strawberry-shake.jpg": {
    "title": "Strawberry Shake · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-strawberry-milkshake-with-whipped-cream-and-a-straw-smsivJclnQM",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-chocolate-shake.jpg": {
    "title": "Chocolate Shake · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/es/fotos/helado-en-vaso-de-vidrio-transparente-L6RfOqJqT8g",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-hummus.jpg": {
    "title": "Hummus · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-plate-of-hummus-pita-bread-and-a-bowl-of-olive-oil-n5I4Ix008-0",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-brownie.jpg": {
    "title": "Brownie · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/square-brownies-O0H6MVtAP9M",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-chocolate-cake.jpg": {
    "title": "Chocolate Cake · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/chocolate-cake-on-white-ceramic-plate-TIctev58ij8",
    "licenseUrl": "https://unsplash.com/license"
  },
  "photo-icecream.jpg": {
    "title": "Icecream · Unsplash",
    "license": "Unsplash License",
    "source": "https://unsplash.com/photos/a-scoop-of-ice-cream-with-sprinkles-on-a-pink-background-Fdm1jr-VlcI",
    "licenseUrl": "https://unsplash.com/license"
  },
  "food-south-indian.png": {
    "title": "South Indian breakfast with dosa, idli, medu vada, sambar and coconut chutney.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "food-thai-curry.png": {
    "title": "Thai green coconut curry with tofu, vegetables, herbs and jasmine rice.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "food-korean-bowl.png": {
    "title": "Korean vegetable and tofu bibimbap rice bowl with colourful vegetables.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "food-indian-chaat.png": {
    "title": "Indian samosa chaat with chickpeas, yogurt, chutneys, sev and coriander.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "food-coastal-fish.png": {
    "title": "Coastal fish in orange coconut curry with steamed rice.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "food-indian-sweets.png": {
    "title": "Indian dessert platter with gulab jamun, pistachio kulfi and mishti doi.",
    "license": "AI-generated food illustration for QuickBite",
    "source": "",
    "licenseUrl": ""
  },
  "hero-biryani.png": {
    "title": "Paneer biryani",
    "license": "Generated food illustration from the original QuickBite project",
    "source": "",
    "licenseUrl": ""
  },
  "pizza.png": {
    "title": "Margherita pizza",
    "license": "Generated food illustration from the original QuickBite project",
    "source": "",
    "licenseUrl": ""
  },
  "burger.png": {
    "title": "Paneer burger",
    "license": "Generated food illustration from the original QuickBite project",
    "source": "",
    "licenseUrl": ""
  },
  "noodles.png": {
    "title": "Vegetable noodles",
    "license": "Generated food illustration from the original QuickBite project",
    "source": "",
    "licenseUrl": ""
  }
};

  static const generatedCredits = <String, Map<String, String>>{
  "dish-paneer-dum-biryani.jpg": {
    "title": "Paneer Dum Biryani",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-butter-chicken-rice.jpg": {
    "title": "Butter Chicken & Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-dal-makhani-bowl.jpg": {
    "title": "Dal Makhani Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chole-jeera-rice.jpg": {
    "title": "Chole & Jeera Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-vegetable-pulao.jpg": {
    "title": "Vegetable Pulao",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-hyderabadi-chicken-biryani.jpg": {
    "title": "Hyderabadi Chicken Biryani",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-classic-margherita.jpg": {
    "title": "Classic Margherita",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-roasted-vegetable-pizza.jpg": {
    "title": "Roasted Vegetable Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-pesto-pizza.jpg": {
    "title": "Chicken Pesto Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-four-cheese-pizza.jpg": {
    "title": "Four Cheese Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-truffle-pizza.jpg": {
    "title": "Mushroom Truffle Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-spicy-corn-pizza.jpg": {
    "title": "Spicy Corn Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-crispy-paneer-burger.jpg": {
    "title": "Crispy Paneer Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-smoky-garden-burger.jpg": {
    "title": "Smoky Garden Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-double-cheese-chicken-burger.jpg": {
    "title": "Double Cheese Chicken Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-swiss-burger.jpg": {
    "title": "Mushroom Swiss Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-spicy-chickpea-burger.jpg": {
    "title": "Spicy Chickpea Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-bbq-chicken-burger.jpg": {
    "title": "BBQ Chicken Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-sesame-vegetable-noodles.jpg": {
    "title": "Sesame Vegetable Noodles",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chilli-garlic-noodles.jpg": {
    "title": "Chilli Garlic Noodles",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-hakka-noodles.jpg": {
    "title": "Chicken Hakka Noodles",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-noodle-bowl.jpg": {
    "title": "Mushroom Noodle Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-schezwan-tofu-noodles.jpg": {
    "title": "Schezwan Tofu Noodles",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-prawn-pepper-noodles.jpg": {
    "title": "Prawn Pepper Noodles",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-masala-dosa.jpg": {
    "title": "Masala Dosa",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-ghee-podi-idli.jpg": {
    "title": "Ghee Podi Idli",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-onion-uttapam.jpg": {
    "title": "Onion Uttapam",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-medu-vada.jpg": {
    "title": "Medu Vada",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mysore-masala-dosa.jpg": {
    "title": "Mysore Masala Dosa",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-egg-dosa.jpg": {
    "title": "Egg Dosa",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-black-bean-tacos.jpg": {
    "title": "Black Bean Tacos",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-burrito.jpg": {
    "title": "Chicken Burrito",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-corn-quesadilla.jpg": {
    "title": "Corn Quesadilla",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chipotle-paneer-bowl.jpg": {
    "title": "Chipotle Paneer Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-loaded-nachos.jpg": {
    "title": "Loaded Nachos",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-fish-tacos.jpg": {
    "title": "Fish Tacos",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-avocado-cucumber-maki.jpg": {
    "title": "Avocado Cucumber Maki",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-salmon-sushi-roll.jpg": {
    "title": "Salmon Sushi Roll",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tofu-teriyaki-bowl.jpg": {
    "title": "Tofu Teriyaki Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-katsu-bowl.jpg": {
    "title": "Chicken Katsu Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-vegetable-gyoza.jpg": {
    "title": "Vegetable Gyoza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-miso-ramen.jpg": {
    "title": "Mushroom Miso Ramen",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tofu-green-curry.jpg": {
    "title": "Tofu Green Curry",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-red-curry.jpg": {
    "title": "Chicken Red Curry",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-vegetable-pad-thai.jpg": {
    "title": "Vegetable Pad Thai",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-basil-chicken-rice.jpg": {
    "title": "Basil Chicken Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tom-kha-mushroom-soup.jpg": {
    "title": "Tom Kha Mushroom Soup",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mango-sticky-rice.jpg": {
    "title": "Mango Sticky Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tofu-bibimbap.jpg": {
    "title": "Tofu Bibimbap",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-korean-fried-chicken.jpg": {
    "title": "Korean Fried Chicken",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-vegetable-japchae.jpg": {
    "title": "Vegetable Japchae",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-bulgogi-bowl.jpg": {
    "title": "Mushroom Bulgogi Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-kimchi-rice.jpg": {
    "title": "Kimchi Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-mandu.jpg": {
    "title": "Chicken Mandu",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-falafel-pita.jpg": {
    "title": "Falafel Pita",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-greek-salad.jpg": {
    "title": "Greek Salad",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-grilled-chicken-plate.jpg": {
    "title": "Grilled Chicken Plate",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-roasted-vegetable-couscous.jpg": {
    "title": "Roasted Vegetable Couscous",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-hummus-mezze.jpg": {
    "title": "Hummus Mezze",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-halloumi-wrap.jpg": {
    "title": "Halloumi Wrap",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-falafel-shawarma.jpg": {
    "title": "Falafel Shawarma",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-shawarma.jpg": {
    "title": "Chicken Shawarma",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-hummus-pita.jpg": {
    "title": "Hummus & Pita",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-baba-ganoush.jpg": {
    "title": "Baba Ganoush",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tabbouleh-bowl.jpg": {
    "title": "Tabbouleh Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-lamb-kofta-plate.jpg": {
    "title": "Lamb Kofta Plate",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-rainbow-quinoa-bowl.jpg": {
    "title": "Rainbow Quinoa Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-grilled-chicken-salad.jpg": {
    "title": "Grilled Chicken Salad",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-avocado-toast.jpg": {
    "title": "Avocado Toast",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tofu-protein-bowl.jpg": {
    "title": "Tofu Protein Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-beetroot-hummus-bowl.jpg": {
    "title": "Beetroot Hummus Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-roasted-pumpkin-salad.jpg": {
    "title": "Roasted Pumpkin Salad",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chocolate-brownie.jpg": {
    "title": "Chocolate Brownie",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-strawberry-cheesecake.jpg": {
    "title": "Strawberry Cheesecake",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-gulab-jamun.jpg": {
    "title": "Gulab Jamun",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mango-sundae.jpg": {
    "title": "Mango Sundae",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chocolate-lava-cake.jpg": {
    "title": "Chocolate Lava Cake",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-pistachio-kulfi.jpg": {
    "title": "Pistachio Kulfi",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-butter-croissant.jpg": {
    "title": "Butter Croissant",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chocolate-croissant.jpg": {
    "title": "Chocolate Croissant",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-cinnamon-roll.jpg": {
    "title": "Cinnamon Roll",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-garlic-focaccia.jpg": {
    "title": "Garlic Focaccia",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-banana-walnut-loaf.jpg": {
    "title": "Banana Walnut Loaf",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mushroom-puff.jpg": {
    "title": "Mushroom Puff",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-berry-pancakes.jpg": {
    "title": "Berry Pancakes",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-masala-omelette-toast.jpg": {
    "title": "Masala Omelette Toast",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-peanut-butter-oats.jpg": {
    "title": "Peanut Butter Oats",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-poha-bowl.jpg": {
    "title": "Poha Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-waffle-banana.jpg": {
    "title": "Waffle & Banana",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-egg-breakfast-sandwich.jpg": {
    "title": "Egg Breakfast Sandwich",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-pani-puri-kit.jpg": {
    "title": "Pani Puri Kit",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-pav-bhaji.jpg": {
    "title": "Pav Bhaji",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-samosa-chaat.jpg": {
    "title": "Samosa Chaat",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-dahi-puri.jpg": {
    "title": "Dahi Puri",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-paneer-kathi-roll.jpg": {
    "title": "Paneer Kathi Roll",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-kathi-roll.jpg": {
    "title": "Chicken Kathi Roll",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-crispy-fish-chips.jpg": {
    "title": "Crispy Fish & Chips",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-garlic-butter-prawns.jpg": {
    "title": "Garlic Butter Prawns",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-goan-fish-curry.jpg": {
    "title": "Goan Fish Curry",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-pepper-squid.jpg": {
    "title": "Pepper Squid",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-prawn-fried-rice.jpg": {
    "title": "Prawn Fried Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-coastal-tofu-curry.jpg": {
    "title": "Coastal Tofu Curry",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-tandoori-paneer-skewers.jpg": {
    "title": "Tandoori Paneer Skewers",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-smoked-chicken-wings.jpg": {
    "title": "Smoked Chicken Wings",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-charred-mushroom-skewers.jpg": {
    "title": "Charred Mushroom Skewers",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chicken-tikka-plate.jpg": {
    "title": "Chicken Tikka Plate",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-bbq-corn-ribs.jpg": {
    "title": "BBQ Corn Ribs",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-lamb-seekh-kebab.jpg": {
    "title": "Lamb Seekh Kebab",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-iced-vanilla-latte.jpg": {
    "title": "Iced Vanilla Latte",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mango-lassi.jpg": {
    "title": "Mango Lassi",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-cold-brew-coffee.jpg": {
    "title": "Cold Brew Coffee",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-strawberry-milkshake.jpg": {
    "title": "Strawberry Milkshake",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mint-lime-cooler.jpg": {
    "title": "Mint Lime Cooler",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-chocolate-frappe.jpg": {
    "title": "Chocolate Frappe",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-kolkata-chicken-biryani.jpg": {
    "title": "Kolkata Chicken Biryani",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-luchi-aloo-dum.jpg": {
    "title": "Luchi & Aloo Dum",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-cholar-dal-rice.jpg": {
    "title": "Cholar Dal & Rice",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-shorshe-fish.jpg": {
    "title": "Shorshe Fish",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-vegetable-chop.jpg": {
    "title": "Vegetable Chop",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mishti-doi.jpg": {
    "title": "Mishti Doi",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-garden-vegetable-biryani.jpg": {
    "title": "Garden Vegetable Biryani",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-saffron-rice-bowl.jpg": {
    "title": "Saffron Rice Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-family-paneer-biryani.jpg": {
    "title": "Family Paneer Biryani",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-basil-mozzarella-pizza.jpg": {
    "title": "Basil & Mozzarella Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-double-cheese-paneer-burger.jpg": {
    "title": "Double Cheese Paneer Burger",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-paneer-burger-fries.jpg": {
    "title": "Paneer Burger & Fries",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-noodles-dumplings.jpg": {
    "title": "Noodles & Dumplings",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-charred-paneer-rice-bowl.jpg": {
    "title": "Charred Paneer Rice Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mint-saffron-bowl.jpg": {
    "title": "Mint & Saffron Bowl",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-biryani-feast-for-two.jpg": {
    "title": "Biryani Feast for Two",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-seasonal-rice-special.jpg": {
    "title": "Seasonal Rice Special",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-rustic-tomato-pizza.jpg": {
    "title": "Rustic Tomato Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-basil-garden-pizza.jpg": {
    "title": "Basil Garden Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-mozzarella-sourdough-pizza.jpg": {
    "title": "Mozzarella Sourdough Pizza",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  },
  "dish-large-margherita.jpg": {
    "title": "Large Margherita",
    "license": "AI-generated illustration made for this QuickBite menu.",
    "source": "",
    "licenseUrl": ""
  }
};

  static Map<String, String>? creditFor(String file) =>
      generatedCredits[file] ?? credits[file];

  static String resolve(String original, {String? dishName, String? cuisine}) {
    // The backend chooses photo/ paths from the exact dish name. Keep that
    // product-specific photo ahead of generated illustrations in the catalog.
    if (original.startsWith('photo/')) return original;
    // Use the current dish-specific artwork chosen by the API before older
    // hand-picked category artwork. This keeps newly generated images visible.
    if (original.startsWith('generated/')) return original;
    final exactName = dishName?.trim();
    if (exactName != null && generatedByDish.containsKey(exactName)) {
      return generatedByDish[exactName]!;
    }
    if (exactName != null && byDish.containsKey(exactName)) {
      return byDish[exactName]!;
    }
    final recipe = exactName?.split(' · ').first.trim();
    if (recipe != null && generatedByDish.containsKey(recipe)) {
      return generatedByDish[recipe]!;
    }
    if (recipe != null && byDish.containsKey(recipe)) return byDish[recipe]!;
    // An explicit kitchen cover must not be overwritten by its cuisine cover.
    if (original.startsWith('dish-') && generatedCredits.containsKey(original)) {
      return original;
    }
    // Legacy emoji fields carry no product-specific image. For an unknown
    // dish, return an unavailable placeholder rather than a misleading meal.
    if (dishName != null && (original.isEmpty || original.startsWith('emoji:'))) {
      return '';
    }
    if (cuisine != null && byCuisine.containsKey(cuisine)) return byCuisine[cuisine]!;
    if (legacyImages.containsKey(original)) return legacyImages[original]!;
    if (original.isEmpty || original.startsWith('emoji:')) return '';
    return original;
  }
}
