import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Clock, ChefHat, Star, Utensils } from "lucide-react";
import { ScrollArea } from "@/components/ui/scroll-area";

interface Recipe {
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

interface RecipeDetailsDialogProps {
  recipe: Recipe | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const RecipeDetailsDialog = ({ recipe, open, onOpenChange }: RecipeDetailsDialogProps) => {
  if (!recipe) return null;

  const totalTime = recipe.prep_time + recipe.cook_time;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] p-0">
        <ScrollArea className="max-h-[90vh]">
          {recipe.image_url && (
            <div className="relative h-64 w-full overflow-hidden">
              <img 
                src={recipe.image_url} 
                alt={recipe.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-transparent" />
            </div>
          )}
          
          <div className="p-6 space-y-6">
            <DialogHeader>
              <DialogTitle className="text-3xl font-bold">{recipe.name}</DialogTitle>
              <p className="text-muted-foreground mt-2">{recipe.description}</p>
            </DialogHeader>

            <div className="flex flex-wrap items-center gap-3">
              <div className="flex items-center gap-2 bg-muted px-3 py-1.5 rounded-full">
                <Clock className="w-4 h-4" />
                <span className="text-sm font-medium">{totalTime} minutes</span>
              </div>
              <div className="flex items-center gap-2 bg-muted px-3 py-1.5 rounded-full">
                <ChefHat className="w-4 h-4" />
                <span className="text-sm font-medium capitalize">{recipe.difficulty}</span>
              </div>
              {recipe.health_score && (
                <div className="flex items-center gap-2 bg-primary/10 px-3 py-1.5 rounded-full">
                  <Star className="w-4 h-4 fill-primary text-primary" />
                  <span className="text-sm font-medium text-primary">Health Score: {recipe.health_score}</span>
                </div>
              )}
              {recipe.cuisine && (
                <Badge variant="outline">{recipe.cuisine}</Badge>
              )}
            </div>

            {recipe.dietary_tags && recipe.dietary_tags.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {recipe.dietary_tags.map((tag) => (
                  <Badge key={tag} variant="secondary">
                    {tag}
                  </Badge>
                ))}
              </div>
            )}

            {recipe.nutrition && (
              <div className="bg-gradient-primary/5 rounded-lg p-4">
                <h3 className="font-semibold mb-3 flex items-center gap-2">
                  <Utensils className="w-4 h-4" />
                  Nutrition Information
                </h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <div className="text-center p-3 bg-background rounded-lg">
                    <div className="text-2xl font-bold text-primary">{recipe.nutrition.calories}</div>
                    <div className="text-xs text-muted-foreground">Calories</div>
                  </div>
                  <div className="text-center p-3 bg-background rounded-lg">
                    <div className="text-2xl font-bold text-secondary">{recipe.nutrition.protein}</div>
                    <div className="text-xs text-muted-foreground">Protein</div>
                  </div>
                  <div className="text-center p-3 bg-background rounded-lg">
                    <div className="text-2xl font-bold text-accent">{recipe.nutrition.carbs}</div>
                    <div className="text-xs text-muted-foreground">Carbs</div>
                  </div>
                  <div className="text-center p-3 bg-background rounded-lg">
                    <div className="text-2xl font-bold text-foreground">{recipe.nutrition.fat}</div>
                    <div className="text-xs text-muted-foreground">Fat</div>
                  </div>
                </div>
              </div>
            )}

            <Separator />

            <div>
              <h3 className="font-semibold text-lg mb-3">Ingredients</h3>
              <ul className="space-y-2">
                {recipe.ingredients.map((ingredient, index) => (
                  <li key={index} className="flex items-start gap-2">
                    <span className="text-primary mt-1.5">•</span>
                    <span>
                      <span className="font-medium">{ingredient.amount}</span> {ingredient.name}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            <Separator />

            <div>
              <h3 className="font-semibold text-lg mb-3">Instructions</h3>
              <ol className="space-y-4">
                {recipe.instructions.map((instruction) => (
                  <li key={instruction.step} className="flex gap-3">
                    <span className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-primary text-primary-foreground flex items-center justify-center font-semibold text-sm">
                      {instruction.step}
                    </span>
                    <p className="flex-1 pt-1">{instruction.instruction}</p>
                  </li>
                ))}
              </ol>
            </div>
          </div>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
};