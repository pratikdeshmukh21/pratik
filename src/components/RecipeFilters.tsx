import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { X } from "lucide-react";

interface RecipeFiltersProps {
  selectedDifficulty: string;
  selectedCuisine: string;
  selectedDietary: string[];
  onDifficultyChange: (value: string) => void;
  onCuisineChange: (value: string) => void;
  onDietaryToggle: (tag: string) => void;
  onClearAll: () => void;
}

const DIETARY_OPTIONS = [
  'vegetarian',
  'vegan',
  'gluten-free',
  'keto',
  'paleo',
  'high-protein',
];

const CUISINE_OPTIONS = [
  'All Cuisines',
  'Italian',
  'Mediterranean',
  'Mexican',
  'Asian',
  'Indian',
  'American',
  'Thai',
  'Greek',
  'Chinese',
  'Japanese',
  'Korean',
  'Moroccan',
  'Cajun',
];

export const RecipeFilters = ({
  selectedDifficulty,
  selectedCuisine,
  selectedDietary,
  onDifficultyChange,
  onCuisineChange,
  onDietaryToggle,
  onClearAll,
}: RecipeFiltersProps) => {
  const hasActiveFilters = 
    selectedDifficulty !== 'all' || 
    selectedCuisine !== 'All Cuisines' || 
    selectedDietary.length > 0;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <Select value={selectedDifficulty} onValueChange={onDifficultyChange}>
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="Difficulty" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Levels</SelectItem>
            <SelectItem value="easy">Easy</SelectItem>
            <SelectItem value="medium">Medium</SelectItem>
            <SelectItem value="hard">Hard</SelectItem>
          </SelectContent>
        </Select>

        <Select value={selectedCuisine} onValueChange={onCuisineChange}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="Cuisine" />
          </SelectTrigger>
          <SelectContent>
            {CUISINE_OPTIONS.map((cuisine) => (
              <SelectItem key={cuisine} value={cuisine}>
                {cuisine}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {hasActiveFilters && (
          <Button
            variant="ghost"
            size="sm"
            onClick={onClearAll}
            className="text-muted-foreground hover:text-foreground"
          >
            <X className="w-4 h-4 mr-1" />
            Clear All
          </Button>
        )}
      </div>

      <div className="space-y-2">
        <p className="text-sm font-medium text-muted-foreground">Dietary Preferences</p>
        <div className="flex flex-wrap gap-2">
          {DIETARY_OPTIONS.map((option) => {
            const isSelected = selectedDietary.includes(option);
            return (
              <Badge
                key={option}
                variant={isSelected ? "default" : "outline"}
                className="cursor-pointer hover:bg-primary/90 transition-colors capitalize"
                onClick={() => onDietaryToggle(option)}
              >
                {option}
              </Badge>
            );
          })}
        </div>
      </div>
    </div>
  );
};