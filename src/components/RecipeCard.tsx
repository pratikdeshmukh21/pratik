import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Clock, ChefHat, Heart, Star } from "lucide-react";

interface Recipe {
  id?: string;
  name: string;
  description: string;
  prep_time: number;
  cook_time: number;
  difficulty: string;
  cuisine: string;
  dietary_tags: string[];
  health_score: number;
  image_url?: string;
  nutrition?: {
    calories: number;
    protein: string;
    carbs: string;
    fat: string;
  };
}

interface RecipeCardProps {
  recipe: Recipe;
  onViewDetails: () => void;
  isFavorite?: boolean;
  onToggleFavorite?: () => void;
}

export const RecipeCard = ({ recipe, onViewDetails, isFavorite, onToggleFavorite }: RecipeCardProps) => {
  const totalTime = recipe.prep_time + recipe.cook_time;
  
  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty?.toLowerCase()) {
      case 'easy': return 'bg-primary/10 text-primary border-primary/20';
      case 'medium': return 'bg-secondary/10 text-secondary border-secondary/20';
      case 'hard': return 'bg-accent/10 text-accent border-accent/20';
      default: return 'bg-muted text-muted-foreground';
    }
  };

  const getHealthScoreColor = (score: number) => {
    if (score >= 85) return 'text-primary';
    if (score >= 70) return 'text-secondary';
    return 'text-muted-foreground';
  };

  return (
    <Card className="group overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-1">
      <div className="relative h-48 overflow-hidden bg-gradient-primary">
        {recipe.image_url ? (
          <img 
            src={recipe.image_url} 
            alt={recipe.name}
            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <ChefHat className="w-16 h-16 text-primary-foreground opacity-50" />
          </div>
        )}
        {onToggleFavorite && (
          <Button
            size="icon"
            variant={isFavorite ? "default" : "secondary"}
            className="absolute top-3 right-3 rounded-full shadow-md"
            onClick={(e) => {
              e.stopPropagation();
              onToggleFavorite();
            }}
          >
            <Heart className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
          </Button>
        )}
        {recipe.health_score && (
          <div className="absolute bottom-3 right-3 bg-background/90 backdrop-blur-sm px-3 py-1.5 rounded-full flex items-center gap-1.5 shadow-md">
            <Star className={`w-4 h-4 ${getHealthScoreColor(recipe.health_score)} fill-current`} />
            <span className={`font-semibold text-sm ${getHealthScoreColor(recipe.health_score)}`}>
              {recipe.health_score}
            </span>
          </div>
        )}
      </div>
      
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2 mb-2">
          <CardTitle className="text-xl line-clamp-1">{recipe.name}</CardTitle>
        </div>
        <CardDescription className="line-clamp-2 text-sm">
          {recipe.description}
        </CardDescription>
      </CardHeader>

      <CardContent className="space-y-4">
        <div className="flex items-center gap-4 text-sm text-muted-foreground">
          <div className="flex items-center gap-1.5">
            <Clock className="w-4 h-4" />
            <span>{totalTime} min</span>
          </div>
          <Badge variant="outline" className={getDifficultyColor(recipe.difficulty)}>
            {recipe.difficulty}
          </Badge>
          {recipe.cuisine && (
            <span className="text-xs">{recipe.cuisine}</span>
          )}
        </div>

        {recipe.dietary_tags && recipe.dietary_tags.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {recipe.dietary_tags.slice(0, 3).map((tag) => (
              <Badge key={tag} variant="secondary" className="text-xs">
                {tag}
              </Badge>
            ))}
            {recipe.dietary_tags.length > 3 && (
              <Badge variant="secondary" className="text-xs">
                +{recipe.dietary_tags.length - 3}
              </Badge>
            )}
          </div>
        )}

        {recipe.nutrition && (
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="bg-muted rounded-lg p-2">
              <div className="font-semibold text-foreground">{recipe.nutrition.calories}</div>
              <div className="text-muted-foreground">Calories</div>
            </div>
            <div className="bg-muted rounded-lg p-2">
              <div className="font-semibold text-foreground">{recipe.nutrition.protein}</div>
              <div className="text-muted-foreground">Protein</div>
            </div>
          </div>
        )}

        <Button 
          onClick={onViewDetails}
          className="w-full bg-gradient-primary hover:opacity-90 transition-opacity"
        >
          View Recipe
        </Button>
      </CardContent>
    </Card>
  );
};