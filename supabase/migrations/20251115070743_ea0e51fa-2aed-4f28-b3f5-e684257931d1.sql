-- Create recipes table
CREATE TABLE IF NOT EXISTS public.recipes (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  description text,
  ingredients jsonb NOT NULL DEFAULT '[]'::jsonb,
  instructions jsonb NOT NULL DEFAULT '[]'::jsonb,
  nutrition jsonb DEFAULT '{}'::jsonb,
  prep_time integer, -- in minutes
  cook_time integer, -- in minutes
  difficulty text CHECK (difficulty IN ('easy', 'medium', 'hard')),
  cuisine text,
  dietary_tags text[] DEFAULT ARRAY[]::text[],
  health_score integer CHECK (health_score >= 0 AND health_score <= 100),
  image_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create user_favorites table
CREATE TABLE IF NOT EXISTS public.user_favorites (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Create recipe_ratings table
CREATE TABLE IF NOT EXISTS public.recipe_ratings (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Enable RLS
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for recipes (public read, no write for now)
CREATE POLICY "Recipes are viewable by everyone" 
  ON public.recipes 
  FOR SELECT 
  USING (true);

-- RLS Policies for user_favorites
CREATE POLICY "Users can view their own favorites" 
  ON public.user_favorites 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own favorites" 
  ON public.user_favorites 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" 
  ON public.user_favorites 
  FOR DELETE 
  USING (auth.uid() = user_id);

-- RLS Policies for recipe_ratings
CREATE POLICY "Ratings are viewable by everyone" 
  ON public.recipe_ratings 
  FOR SELECT 
  USING (true);

CREATE POLICY "Users can create their own ratings" 
  ON public.recipe_ratings 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ratings" 
  ON public.recipe_ratings 
  FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own ratings" 
  ON public.recipe_ratings 
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_recipes_updated_at
  BEFORE UPDATE ON public.recipes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_recipe_ratings_updated_at
  BEFORE UPDATE ON public.recipe_ratings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert sample recipes
INSERT INTO public.recipes (name, description, ingredients, instructions, nutrition, prep_time, cook_time, difficulty, cuisine, dietary_tags, health_score, image_url) VALUES
('Mediterranean Quinoa Bowl', 'A healthy and colorful bowl packed with protein and fresh vegetables', 
 '[{"name":"quinoa","amount":"1 cup"},{"name":"cherry tomatoes","amount":"1 cup"},{"name":"cucumber","amount":"1"},{"name":"feta cheese","amount":"1/2 cup"},{"name":"olive oil","amount":"2 tbsp"},{"name":"lemon","amount":"1"}]'::jsonb,
 '[{"step":1,"instruction":"Cook quinoa according to package instructions"},{"step":2,"instruction":"Dice cucumber and halve cherry tomatoes"},{"step":3,"instruction":"Mix all ingredients in a bowl"},{"step":4,"instruction":"Drizzle with olive oil and lemon juice"},{"step":5,"instruction":"Top with crumbled feta cheese"}]'::jsonb,
 '{"calories":420,"protein":"15g","carbs":"52g","fat":"18g","fiber":"8g"}'::jsonb,
 15, 15, 'easy', 'Mediterranean', ARRAY['vegetarian', 'gluten-free'], 92, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'),

('Grilled Salmon with Asparagus', 'Omega-3 rich salmon with tender asparagus spears',
 '[{"name":"salmon fillet","amount":"6 oz"},{"name":"asparagus","amount":"1 bunch"},{"name":"garlic","amount":"3 cloves"},{"name":"lemon","amount":"1"},{"name":"olive oil","amount":"2 tbsp"},{"name":"herbs","amount":"to taste"}]'::jsonb,
 '[{"step":1,"instruction":"Preheat grill to medium-high heat"},{"step":2,"instruction":"Season salmon with salt, pepper, and herbs"},{"step":3,"instruction":"Toss asparagus with olive oil and minced garlic"},{"step":4,"instruction":"Grill salmon 4-5 minutes per side"},{"step":5,"instruction":"Grill asparagus until tender, about 8 minutes"}]'::jsonb,
 '{"calories":380,"protein":"35g","carbs":"12g","fat":"22g","fiber":"5g"}'::jsonb,
 10, 15, 'easy', 'American', ARRAY['keto', 'paleo', 'gluten-free'], 95, 'https://images.unsplash.com/photo-1467003909585-2f8a72700288'),

('Chickpea Curry', 'Aromatic Indian curry with protein-packed chickpeas',
 '[{"name":"chickpeas","amount":"2 cans"},{"name":"coconut milk","amount":"1 can"},{"name":"onion","amount":"1"},{"name":"tomatoes","amount":"2"},{"name":"curry powder","amount":"2 tbsp"},{"name":"ginger","amount":"1 inch"},{"name":"garlic","amount":"4 cloves"}]'::jsonb,
 '[{"step":1,"instruction":"Sauté diced onion, ginger, and garlic"},{"step":2,"instruction":"Add curry powder and cook for 1 minute"},{"step":3,"instruction":"Add diced tomatoes and cook until soft"},{"step":4,"instruction":"Pour in coconut milk and chickpeas"},{"step":5,"instruction":"Simmer for 20 minutes"},{"step":6,"instruction":"Serve over rice"}]'::jsonb,
 '{"calories":340,"protein":"12g","carbs":"45g","fat":"14g","fiber":"10g"}'::jsonb,
 10, 25, 'medium', 'Indian', ARRAY['vegan', 'vegetarian'], 88, 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd');

-- Insert more sample recipes
INSERT INTO public.recipes (name, description, ingredients, instructions, nutrition, prep_time, cook_time, difficulty, cuisine, dietary_tags, health_score) VALUES
('Greek Chicken Souvlaki', 'Marinated grilled chicken skewers with tzatziki',
 '[{"name":"chicken breast","amount":"1 lb"},{"name":"greek yogurt","amount":"1 cup"},{"name":"lemon","amount":"2"},{"name":"garlic","amount":"4 cloves"},{"name":"oregano","amount":"2 tsp"},{"name":"cucumber","amount":"1"}]'::jsonb,
 '[{"step":1,"instruction":"Marinate chicken in yogurt, lemon, garlic, and oregano for 2 hours"},{"step":2,"instruction":"Thread chicken onto skewers"},{"step":3,"instruction":"Grill for 10-12 minutes, turning occasionally"},{"step":4,"instruction":"Make tzatziki with yogurt and cucumber"},{"step":5,"instruction":"Serve with pita bread"}]'::jsonb,
 '{"calories":285,"protein":"38g","carbs":"8g","fat":"10g","fiber":"2g"}'::jsonb,
 130, 12, 'medium', 'Greek', ARRAY['high-protein'], 90),

('Avocado Toast Supreme', 'Elevated avocado toast with poached egg and microgreens',
 '[{"name":"whole grain bread","amount":"2 slices"},{"name":"avocado","amount":"1"},{"name":"eggs","amount":"2"},{"name":"microgreens","amount":"1 cup"},{"name":"cherry tomatoes","amount":"1/2 cup"},{"name":"everything bagel seasoning","amount":"1 tsp"}]'::jsonb,
 '[{"step":1,"instruction":"Toast bread until golden"},{"step":2,"instruction":"Mash avocado with salt and pepper"},{"step":3,"instruction":"Poach eggs in simmering water"},{"step":4,"instruction":"Spread avocado on toast"},{"step":5,"instruction":"Top with poached egg, microgreens, and tomatoes"},{"step":6,"instruction":"Sprinkle with everything bagel seasoning"}]'::jsonb,
 '{"calories":395,"protein":"18g","carbs":"35g","fat":"22g","fiber":"12g"}'::jsonb,
 10, 8, 'easy', 'American', ARRAY['vegetarian'], 87),

('Thai Basil Stir-Fry', 'Quick and flavorful Thai-inspired stir-fry',
 '[{"name":"tofu or chicken","amount":"12 oz"},{"name":"thai basil","amount":"2 cups"},{"name":"bell peppers","amount":"2"},{"name":"soy sauce","amount":"3 tbsp"},{"name":"fish sauce","amount":"1 tbsp"},{"name":"chili","amount":"2"},{"name":"garlic","amount":"5 cloves"}]'::jsonb,
 '[{"step":1,"instruction":"Heat wok over high heat"},{"step":2,"instruction":"Stir-fry protein until cooked"},{"step":3,"instruction":"Add garlic and chili"},{"step":4,"instruction":"Add bell peppers and sauces"},{"step":5,"instruction":"Toss in Thai basil and serve immediately"}]'::jsonb,
 '{"calories":310,"protein":"28g","carbs":"22g","fat":"12g","fiber":"4g"}'::jsonb,
 15, 10, 'easy', 'Thai', ARRAY['gluten-free'], 85);

-- Add more diverse recipes
INSERT INTO public.recipes (name, description, ingredients, instructions, nutrition, prep_time, cook_time, difficulty, cuisine, dietary_tags, health_score) VALUES
('Moroccan Vegetable Tagine', 'Slow-cooked aromatic vegetable stew',
 '[{"name":"sweet potato","amount":"2"},{"name":"chickpeas","amount":"1 can"},{"name":"carrots","amount":"3"},{"name":"zucchini","amount":"2"},{"name":"dried apricots","amount":"1/2 cup"},{"name":"ras el hanout","amount":"2 tbsp"},{"name":"vegetable broth","amount":"2 cups"}]'::jsonb,
 '[{"step":1,"instruction":"Chop all vegetables into chunks"},{"step":2,"instruction":"Brown vegetables in tagine or dutch oven"},{"step":3,"instruction":"Add spices and toast briefly"},{"step":4,"instruction":"Pour in broth and add apricots"},{"step":5,"instruction":"Simmer covered for 45 minutes"},{"step":6,"instruction":"Serve over couscous"}]'::jsonb,
 '{"calories":295,"protein":"9g","carbs":"58g","fat":"5g","fiber":"12g"}'::jsonb,
 20, 45, 'medium', 'Moroccan', ARRAY['vegan', 'vegetarian'], 91),

('Korean Bibimbap', 'Colorful rice bowl with vegetables and gochujang',
 '[{"name":"rice","amount":"2 cups"},{"name":"spinach","amount":"2 cups"},{"name":"carrots","amount":"2"},{"name":"mushrooms","amount":"1 cup"},{"name":"bean sprouts","amount":"1 cup"},{"name":"egg","amount":"2"},{"name":"gochujang","amount":"3 tbsp"},{"name":"sesame oil","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Cook rice according to package"},{"step":2,"instruction":"Blanch spinach and bean sprouts separately"},{"step":3,"instruction":"Sauté julienned carrots and mushrooms"},{"step":4,"instruction":"Fry eggs sunny-side up"},{"step":5,"instruction":"Arrange vegetables over rice in bowl"},{"step":6,"instruction":"Top with egg and gochujang"},{"step":7,"instruction":"Mix well before eating"}]'::jsonb,
 '{"calories":485,"protein":"16g","carbs":"72g","fat":"14g","fiber":"6g"}'::jsonb,
 25, 20, 'medium', 'Korean', ARRAY['vegetarian'], 86),

('Caprese Stuffed Chicken', 'Italian-inspired chicken with mozzarella and tomatoes',
 '[{"name":"chicken breast","amount":"4"},{"name":"mozzarella","amount":"8 oz"},{"name":"tomatoes","amount":"2"},{"name":"basil","amount":"1 bunch"},{"name":"balsamic glaze","amount":"1/4 cup"},{"name":"olive oil","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Butterfly chicken breasts"},{"step":2,"instruction":"Layer mozzarella, tomato slices, and basil inside"},{"step":3,"instruction":"Secure with toothpicks"},{"step":4,"instruction":"Season and sear in hot pan"},{"step":5,"instruction":"Transfer to oven and bake at 375°F for 20 minutes"},{"step":6,"instruction":"Drizzle with balsamic glaze"}]'::jsonb,
 '{"calories":365,"protein":"45g","carbs":"8g","fat":"16g","fiber":"2g"}'::jsonb,
 15, 25, 'medium', 'Italian', ARRAY['high-protein'], 88),

('Vegan Buddha Bowl', 'Nutrient-dense bowl with roasted vegetables and tahini',
 '[{"name":"sweet potato","amount":"1"},{"name":"chickpeas","amount":"1 can"},{"name":"kale","amount":"2 cups"},{"name":"quinoa","amount":"1 cup"},{"name":"tahini","amount":"1/4 cup"},{"name":"lemon","amount":"1"},{"name":"avocado","amount":"1"}]'::jsonb,
 '[{"step":1,"instruction":"Roast diced sweet potato at 425°F for 25 minutes"},{"step":2,"instruction":"Toss chickpeas with spices and roast for 20 minutes"},{"step":3,"instruction":"Massage kale with lemon juice"},{"step":4,"instruction":"Cook quinoa according to package"},{"step":5,"instruction":"Whisk tahini with lemon and water for dressing"},{"step":6,"instruction":"Arrange all components in bowl with sliced avocado"}]'::jsonb,
 '{"calories":525,"protein":"18g","carbs":"68g","fat":"22g","fiber":"16g"}'::jsonb,
 15, 30, 'easy', 'International', ARRAY['vegan', 'vegetarian', 'gluten-free'], 94),

('Lemon Herb Baked Cod', 'Light and flaky white fish with fresh herbs',
 '[{"name":"cod fillet","amount":"6 oz"},{"name":"lemon","amount":"2"},{"name":"fresh dill","amount":"3 tbsp"},{"name":"parsley","amount":"3 tbsp"},{"name":"garlic","amount":"3 cloves"},{"name":"white wine","amount":"1/4 cup"},{"name":"olive oil","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Preheat oven to 400°F"},{"step":2,"instruction":"Place cod in baking dish"},{"step":3,"instruction":"Top with minced garlic and herbs"},{"step":4,"instruction":"Pour white wine and lemon juice around fish"},{"step":5,"instruction":"Drizzle with olive oil"},{"step":6,"instruction":"Bake for 15-18 minutes until flaky"}]'::jsonb,
 '{"calories":245,"protein":"32g","carbs":"5g","fat":"10g","fiber":"1g"}'::jsonb,
 10, 18, 'easy', 'Mediterranean', ARRAY['keto', 'paleo', 'gluten-free'], 93),

('Black Bean Tacos', 'Vegetarian tacos with spiced black beans and fresh toppings',
 '[{"name":"black beans","amount":"2 cans"},{"name":"corn tortillas","amount":"8"},{"name":"avocado","amount":"2"},{"name":"red cabbage","amount":"2 cups"},{"name":"lime","amount":"2"},{"name":"cilantro","amount":"1 bunch"},{"name":"cumin","amount":"1 tsp"},{"name":"chili powder","amount":"1 tsp"}]'::jsonb,
 '[{"step":1,"instruction":"Warm tortillas in dry skillet"},{"step":2,"instruction":"Heat beans with cumin and chili powder"},{"step":3,"instruction":"Mash half the beans for texture"},{"step":4,"instruction":"Shred cabbage and toss with lime"},{"step":5,"instruction":"Fill tortillas with beans"},{"step":6,"instruction":"Top with avocado, cabbage, and cilantro"}]'::jsonb,
 '{"calories":385,"protein":"14g","carbs":"58g","fat":"12g","fiber":"18g"}'::jsonb,
 15, 10, 'easy', 'Mexican', ARRAY['vegan', 'vegetarian'], 89),

('Teriyaki Glazed Tofu', 'Crispy tofu with sweet and savory teriyaki sauce',
 '[{"name":"extra firm tofu","amount":"14 oz"},{"name":"soy sauce","amount":"1/4 cup"},{"name":"mirin","amount":"2 tbsp"},{"name":"brown sugar","amount":"2 tbsp"},{"name":"ginger","amount":"1 inch"},{"name":"garlic","amount":"3 cloves"},{"name":"sesame seeds","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Press tofu to remove excess water"},{"step":2,"instruction":"Cut into cubes and pan-fry until golden"},{"step":3,"instruction":"Make teriyaki sauce with soy sauce, mirin, sugar, ginger, and garlic"},{"step":4,"instruction":"Simmer sauce until thickened"},{"step":5,"instruction":"Toss tofu in teriyaki sauce"},{"step":6,"instruction":"Garnish with sesame seeds and serve over rice"}]'::jsonb,
 '{"calories":285,"protein":"18g","carbs":"28g","fat":"10g","fiber":"3g"}'::jsonb,
 20, 15, 'medium', 'Japanese', ARRAY['vegan', 'vegetarian'], 84),

('Spinach and Feta Frittata', 'Protein-packed egg dish perfect for any meal',
 '[{"name":"eggs","amount":"8"},{"name":"spinach","amount":"4 cups"},{"name":"feta cheese","amount":"1 cup"},{"name":"onion","amount":"1"},{"name":"cherry tomatoes","amount":"1 cup"},{"name":"milk","amount":"1/4 cup"},{"name":"olive oil","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Preheat oven to 375°F"},{"step":2,"instruction":"Sauté onions in oven-safe skillet"},{"step":3,"instruction":"Add spinach and wilt"},{"step":4,"instruction":"Whisk eggs with milk"},{"step":5,"instruction":"Pour eggs over vegetables"},{"step":6,"instruction":"Add feta and tomatoes"},{"step":7,"instruction":"Bake for 20-25 minutes until set"}]'::jsonb,
 '{"calories":295,"protein":"20g","carbs":"10g","fat":"20g","fiber":"3g"}'::jsonb,
 10, 25, 'easy', 'Mediterranean', ARRAY['vegetarian', 'gluten-free'], 85),

('Honey Mustard Pork Chops', 'Juicy pork chops with tangy-sweet glaze',
 '[{"name":"pork chops","amount":"4"},{"name":"honey","amount":"3 tbsp"},{"name":"dijon mustard","amount":"2 tbsp"},{"name":"garlic","amount":"3 cloves"},{"name":"thyme","amount":"1 tsp"},{"name":"apple cider vinegar","amount":"1 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Mix honey, mustard, garlic, and vinegar for glaze"},{"step":2,"instruction":"Season pork chops with salt, pepper, and thyme"},{"step":3,"instruction":"Sear chops in hot pan, 3-4 minutes per side"},{"step":4,"instruction":"Brush with honey mustard glaze"},{"step":5,"instruction":"Finish in oven at 375°F for 8-10 minutes"}]'::jsonb,
 '{"calories":340,"protein":"36g","carbs":"18g","fat":"12g","fiber":"0g"}'::jsonb,
 10, 18, 'easy', 'American', ARRAY['gluten-free'], 82),

('Mushroom Risotto', 'Creamy Italian rice dish with earthy mushrooms',
 '[{"name":"arborio rice","amount":"1.5 cups"},{"name":"mixed mushrooms","amount":"12 oz"},{"name":"vegetable broth","amount":"6 cups"},{"name":"parmesan","amount":"1 cup"},{"name":"white wine","amount":"1/2 cup"},{"name":"onion","amount":"1"},{"name":"butter","amount":"3 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Sauté mushrooms until golden, set aside"},{"step":2,"instruction":"Cook diced onion in butter until soft"},{"step":3,"instruction":"Toast rice for 2 minutes"},{"step":4,"instruction":"Add wine and stir until absorbed"},{"step":5,"instruction":"Gradually add warm broth, stirring constantly"},{"step":6,"instruction":"Cook for 20-25 minutes until creamy"},{"step":7,"instruction":"Stir in mushrooms and parmesan"}]'::jsonb,
 '{"calories":420,"protein":"14g","carbs":"58g","fat":"14g","fiber":"3g"}'::jsonb,
 15, 30, 'hard', 'Italian', ARRAY['vegetarian'], 78),

('Cajun Shrimp Pasta', 'Spicy Louisiana-style pasta with succulent shrimp',
 '[{"name":"shrimp","amount":"1 lb"},{"name":"fettuccine","amount":"12 oz"},{"name":"heavy cream","amount":"1 cup"},{"name":"cajun seasoning","amount":"2 tbsp"},{"name":"bell peppers","amount":"2"},{"name":"garlic","amount":"4 cloves"},{"name":"tomatoes","amount":"1 can"}]'::jsonb,
 '[{"step":1,"instruction":"Cook pasta according to package"},{"step":2,"instruction":"Season shrimp with cajun spice"},{"step":3,"instruction":"Sauté shrimp until pink, remove from pan"},{"step":4,"instruction":"Cook garlic and peppers"},{"step":5,"instruction":"Add tomatoes and cream"},{"step":6,"instruction":"Simmer for 10 minutes"},{"step":7,"instruction":"Toss with pasta and shrimp"}]'::jsonb,
 '{"calories":565,"protein":"38g","carbs":"62g","fat":"18g","fiber":"4g"}'::jsonb,
 15, 20, 'medium', 'Cajun', ARRAY['high-protein'], 76),

('Roasted Vegetable Lasagna', 'Hearty vegetarian lasagna with layers of roasted vegetables',
 '[{"name":"lasagna noodles","amount":"12"},{"name":"zucchini","amount":"2"},{"name":"eggplant","amount":"1"},{"name":"bell peppers","amount":"2"},{"name":"ricotta","amount":"2 cups"},{"name":"marinara sauce","amount":"4 cups"},{"name":"mozzarella","amount":"3 cups"}]'::jsonb,
 '[{"step":1,"instruction":"Roast sliced vegetables at 400°F for 25 minutes"},{"step":2,"instruction":"Cook lasagna noodles"},{"step":3,"instruction":"Mix ricotta with egg and herbs"},{"step":4,"instruction":"Layer sauce, noodles, ricotta, vegetables, and mozzarella"},{"step":5,"instruction":"Repeat layers twice"},{"step":6,"instruction":"Bake covered at 375°F for 45 minutes"},{"step":7,"instruction":"Uncover and bake 15 more minutes"}]'::jsonb,
 '{"calories":485,"protein":"24g","carbs":"54g","fat":"20g","fiber":"8g"}'::jsonb,
 30, 60, 'hard', 'Italian', ARRAY['vegetarian'], 81),

('Coconut Curry Noodle Soup', 'Warming Thai-inspired noodle soup with coconut broth',
 '[{"name":"rice noodles","amount":"8 oz"},{"name":"coconut milk","amount":"2 cans"},{"name":"red curry paste","amount":"3 tbsp"},{"name":"bok choy","amount":"2 cups"},{"name":"mushrooms","amount":"1 cup"},{"name":"lime","amount":"2"},{"name":"cilantro","amount":"1 bunch"}]'::jsonb,
 '[{"step":1,"instruction":"Heat curry paste in pot until fragrant"},{"step":2,"instruction":"Pour in coconut milk and vegetable broth"},{"step":3,"instruction":"Add sliced mushrooms and simmer"},{"step":4,"instruction":"Cook noodles according to package"},{"step":5,"instruction":"Add bok choy in last 2 minutes"},{"step":6,"instruction":"Serve topped with lime and cilantro"}]'::jsonb,
 '{"calories":395,"protein":"8g","carbs":"48g","fat":"20g","fiber":"4g"}'::jsonb,
 10, 20, 'easy', 'Thai', ARRAY['vegan', 'vegetarian'], 83),

('Beef and Broccoli Stir-Fry', 'Classic Chinese takeout favorite made healthier',
 '[{"name":"flank steak","amount":"1 lb"},{"name":"broccoli","amount":"4 cups"},{"name":"soy sauce","amount":"1/4 cup"},{"name":"oyster sauce","amount":"2 tbsp"},{"name":"ginger","amount":"1 inch"},{"name":"garlic","amount":"4 cloves"},{"name":"cornstarch","amount":"1 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Slice beef thinly against the grain"},{"step":2,"instruction":"Marinate beef in soy sauce and cornstarch"},{"step":3,"instruction":"Blanch broccoli for 2 minutes"},{"step":4,"instruction":"Stir-fry beef in hot wok until browned"},{"step":5,"instruction":"Add ginger and garlic"},{"step":6,"instruction":"Add broccoli and oyster sauce"},{"step":7,"instruction":"Toss everything together and serve"}]'::jsonb,
 '{"calories":325,"protein":"32g","carbs":"18g","fat":"14g","fiber":"4g"}'::jsonb,
 20, 10, 'medium', 'Chinese', ARRAY['high-protein'], 84),

('Pesto Zucchini Noodles', 'Low-carb spiralized zucchini with homemade pesto',
 '[{"name":"zucchini","amount":"4"},{"name":"basil","amount":"2 cups"},{"name":"pine nuts","amount":"1/3 cup"},{"name":"parmesan","amount":"1/2 cup"},{"name":"garlic","amount":"3 cloves"},{"name":"olive oil","amount":"1/2 cup"},{"name":"cherry tomatoes","amount":"1 cup"}]'::jsonb,
 '[{"step":1,"instruction":"Spiralize zucchini into noodles"},{"step":2,"instruction":"Blend basil, pine nuts, parmesan, garlic, and olive oil for pesto"},{"step":3,"instruction":"Lightly sauté zucchini noodles for 2-3 minutes"},{"step":4,"instruction":"Toss with pesto"},{"step":5,"instruction":"Top with halved cherry tomatoes"}]'::jsonb,
 '{"calories":285,"protein":"9g","carbs":"14g","fat":"24g","fiber":"4g"}'::jsonb,
 15, 5, 'easy', 'Italian', ARRAY['vegetarian', 'keto', 'gluten-free'], 88),

('Maple Glazed Brussels Sprouts', 'Caramelized Brussels sprouts with sweet maple glaze',
 '[{"name":"brussels sprouts","amount":"1.5 lbs"},{"name":"maple syrup","amount":"3 tbsp"},{"name":"balsamic vinegar","amount":"2 tbsp"},{"name":"bacon","amount":"4 slices"},{"name":"pecans","amount":"1/2 cup"},{"name":"olive oil","amount":"2 tbsp"}]'::jsonb,
 '[{"step":1,"instruction":"Halve Brussels sprouts"},{"step":2,"instruction":"Toss with olive oil, salt, and pepper"},{"step":3,"instruction":"Roast at 425°F for 25 minutes"},{"step":4,"instruction":"Cook bacon until crispy, crumble"},{"step":5,"instruction":"Mix maple syrup and balsamic"},{"step":6,"instruction":"Toss roasted sprouts with glaze"},{"step":7,"instruction":"Top with bacon and toasted pecans"}]'::jsonb,
 '{"calories":245,"protein":"8g","carbs":"28g","fat":"12g","fiber":"6g"}'::jsonb,
 10, 30, 'easy', 'American', ARRAY['gluten-free'], 86),

('Sweet Potato Black Bean Burgers', 'Hearty vegetarian burgers packed with flavor',
 '[{"name":"sweet potato","amount":"2"},{"name":"black beans","amount":"1 can"},{"name":"oats","amount":"1/2 cup"},{"name":"cumin","amount":"1 tsp"},{"name":"smoked paprika","amount":"1 tsp"},{"name":"cilantro","amount":"1/4 cup"},{"name":"whole wheat buns","amount":"4"}]'::jsonb,
 '[{"step":1,"instruction":"Roast sweet potatoes until tender"},{"step":2,"instruction":"Mash sweet potatoes and black beans together"},{"step":3,"instruction":"Mix in oats, spices, and cilantro"},{"step":4,"instruction":"Form into 4 patties"},{"step":5,"instruction":"Pan-fry or grill patties 4-5 minutes per side"},{"step":6,"instruction":"Serve on buns with your favorite toppings"}]'::jsonb,
 '{"calories":365,"protein":"14g","carbs":"64g","fat":"6g","fiber":"14g"}'::jsonb,
 15, 35, 'medium', 'American', ARRAY['vegan', 'vegetarian'], 90);