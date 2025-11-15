import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { RecipeCard } from "@/components/RecipeCard";
import { RecipeDetailsDialog } from "@/components/RecipeDetailsDialog";
import { RecipeFilters } from "@/components/RecipeFilters";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Search, Sparkles, ChefHat } from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface Recipe {
  id?: string;
  name: string;
  description: string;
  ingredients: Array<{ name: string; amount: string }>;
  instructions: Array<{ step: number; instruction: string }>;
  nutrition?: {
    calories: number;
    protein: string;
    carbs: string;
    fat: string;
    fiber?: string;
  };
  prep_time: number;
  cook_time: number;
  difficulty: string;
  cuisine: string;
  dietary_tags: string[];
  health_score?: number;
  image_url?: string;
}

const COMMON_INGREDIENTS = [
  'chicken', 'salmon', 'tofu', 'quinoa', 'rice', 'pasta',
  'broccoli', 'spinach', 'tomatoes', 'avocado', 'eggs', 'beans'
];

const Index = () => {
  const [ingredients, setIngredients] = useState("");
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [dbRecipes, setDbRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);
  const [showDialog, setShowDialog] = useState(false);
  const { toast } = useToast();

  // Filters
  const [selectedDifficulty, setSelectedDifficulty] = useState('all');
  const [selectedCuisine, setSelectedCuisine] = useState('All Cuisines');
  const [selectedDietary, setSelectedDietary] = useState<string[]>([]);

  useEffect(() => {
    loadDbRecipes();
  }, []);

  const loadDbRecipes = async () => {
    const { data, error } = await supabase
      .from('recipes')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading recipes:', error);
      return;
    }

    if (data) {
      setDbRecipes(data as any);
      setRecipes(data as any);
    }
  };

  const handleTagToggle = (tag: string) => {
    setSelectedTags(prev =>
      prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
    );
  };

  const generateRecipes = async () => {
    if (!ingredients.trim() && selectedTags.length === 0) {
      toast({
        title: "No ingredients",
        description: "Please enter ingredients or select some suggestions",
        variant: "destructive",
      });
      return;
    }

    setLoading(true);
    try {
      const ingredientList = [
        ...ingredients.split(',').map(i => i.trim()).filter(Boolean),
        ...selectedTags
      ];

      const { data, error } = await supabase.functions.invoke('generate-recipes', {
        body: { 
          ingredients: ingredientList,
          dietary: selectedDietary,
          preferences: `Difficulty: ${selectedDifficulty !== 'all' ? selectedDifficulty : 'any'}`
        }
      });

      if (error) throw error;

      if (data?.recipes) {
        setRecipes(data.recipes);
        toast({
          title: "Recipes generated!",
          description: `Found ${data.recipes.length} delicious recipes for you.`,
        });
      }
    } catch (error: any) {
      console.error('Error generating recipes:', error);
      toast({
        title: "Error",
        description: error.message || "Failed to generate recipes. Please try again.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const filteredRecipes = recipes.filter(recipe => {
    if (selectedDifficulty !== 'all' && recipe.difficulty?.toLowerCase() !== selectedDifficulty) {
      return false;
    }
    if (selectedCuisine !== 'All Cuisines' && recipe.cuisine !== selectedCuisine) {
      return false;
    }
    if (selectedDietary.length > 0) {
      const recipeTags = recipe.dietary_tags || [];
      if (!selectedDietary.some(tag => recipeTags.includes(tag))) {
        return false;
      }
    }
    return true;
  });

  return (
    <div className="min-h-screen bg-background">
      {/* Hero Section */}
      <div className="bg-gradient-hero text-primary-foreground py-16 px-4">
        <div className="max-w-6xl mx-auto text-center space-y-6">
          <div className="flex items-center justify-center gap-3 mb-4">
            <ChefHat className="w-12 h-12" />
            <h1 className="text-4xl md:text-5xl font-bold">
              Smart Recipe Generator Pro
            </h1>
          </div>
          <p className="text-lg md:text-xl opacity-90 max-w-2xl mx-auto">
            AI-Powered Nutrition & Zero-Waste Meal Planning
          </p>
          
          <div className="max-w-2xl mx-auto mt-8 space-y-4">
            <div className="flex gap-2">
              <Input
                placeholder="Enter ingredients (e.g., chicken, tomatoes, spinach)"
                value={ingredients}
                onChange={(e) => setIngredients(e.target.value)}
                className="bg-background/95 backdrop-blur-sm text-foreground flex-1"
                onKeyDown={(e) => e.key === 'Enter' && generateRecipes()}
              />
              <Button
                onClick={generateRecipes}
                disabled={loading}
                size="lg"
                className="bg-secondary hover:bg-secondary/90 text-secondary-foreground"
              >
                {loading ? (
                  <Loader2 className="w-5 h-5 animate-spin" />
                ) : (
                  <>
                    <Sparkles className="w-5 h-5 mr-2" />
                    Generate
                  </>
                )}
              </Button>
            </div>

            <div className="space-y-2">
              <p className="text-sm opacity-75">Quick suggestions:</p>
              <div className="flex flex-wrap gap-2 justify-center">
                {COMMON_INGREDIENTS.map((tag) => (
                  <Badge
                    key={tag}
                    variant={selectedTags.includes(tag) ? "default" : "secondary"}
                    className="cursor-pointer hover:opacity-80 transition-opacity capitalize"
                    onClick={() => handleTagToggle(tag)}
                  >
                    {tag}
                  </Badge>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 py-12 space-y-8">
        <RecipeFilters
          selectedDifficulty={selectedDifficulty}
          selectedCuisine={selectedCuisine}
          selectedDietary={selectedDietary}
          onDifficultyChange={setSelectedDifficulty}
          onCuisineChange={setSelectedCuisine}
          onDietaryToggle={(tag) => {
            setSelectedDietary(prev =>
              prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
            );
          }}
          onClearAll={() => {
            setSelectedDifficulty('all');
            setSelectedCuisine('All Cuisines');
            setSelectedDietary([]);
          }}
        />

        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="text-center space-y-4">
              <Loader2 className="w-12 h-12 animate-spin text-primary mx-auto" />
              <p className="text-muted-foreground">Generating delicious recipes...</p>
            </div>
          </div>
        ) : filteredRecipes.length === 0 ? (
          <div className="text-center py-20 space-y-4">
            <Search className="w-16 h-16 text-muted-foreground mx-auto opacity-50" />
            <div>
              <h3 className="text-xl font-semibold mb-2">No recipes found</h3>
              <p className="text-muted-foreground">
                Try generating some recipes or adjusting your filters
              </p>
            </div>
          </div>
        ) : (
          <div>
            <h2 className="text-2xl font-bold mb-6">
              {recipes === dbRecipes ? 'Recipe Database' : 'Generated Recipes'} 
              <span className="text-muted-foreground ml-2">({filteredRecipes.length})</span>
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredRecipes.map((recipe, index) => (
                <RecipeCard
                  key={recipe.id || index}
                  recipe={recipe}
                  onViewDetails={() => {
                    setSelectedRecipe(recipe);
                    setShowDialog(true);
                  }}
                />
              ))}
            </div>
          </div>
        )}
      </div>

      <RecipeDetailsDialog
        recipe={selectedRecipe}
        open={showDialog}
        onOpenChange={setShowDialog}
      />
    </div>
  );
};

export default Index;