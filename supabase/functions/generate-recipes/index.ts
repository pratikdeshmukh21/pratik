import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { ingredients, dietary, preferences } = await req.json();
    console.log('Generating recipes for:', { ingredients, dietary, preferences });

    const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');
    if (!LOVABLE_API_KEY) {
      throw new Error('LOVABLE_API_KEY is not configured');
    }

    const systemPrompt = `You are an expert AI nutritionist and chef specializing in healthy, creative recipes. 
Your task is to generate 3 diverse, delicious recipes based on the user's ingredients and preferences.

For each recipe, provide:
1. A creative, appetizing name
2. A brief description (1-2 sentences)
3. Complete ingredient list with amounts
4. Step-by-step cooking instructions
5. Detailed nutrition information (calories, protein, carbs, fat, fiber)
6. Preparation time and cooking time (in minutes)
7. Difficulty level (easy, medium, or hard)
8. Cuisine type
9. Dietary tags (vegetarian, vegan, gluten-free, keto, paleo, etc.)
10. Health score (0-100, where 100 is extremely healthy)

Return ONLY a valid JSON array of 3 recipe objects with this exact structure:
[
  {
    "name": "Recipe Name",
    "description": "Brief description",
    "ingredients": [{"name": "ingredient", "amount": "quantity"}],
    "instructions": [{"step": 1, "instruction": "Step description"}],
    "nutrition": {"calories": 400, "protein": "25g", "carbs": "45g", "fat": "12g", "fiber": "8g"},
    "prep_time": 15,
    "cook_time": 30,
    "difficulty": "medium",
    "cuisine": "Italian",
    "dietary_tags": ["vegetarian"],
    "health_score": 85
  }
]`;

    const userPrompt = `Create 3 diverse recipes using these ingredients: ${ingredients.join(', ')}.
${dietary && dietary.length > 0 ? `Dietary restrictions: ${dietary.join(', ')}.` : ''}
${preferences ? `Additional preferences: ${preferences}` : ''}

Make the recipes creative, healthy, and diverse in cuisine types. Ensure each recipe has a health score above 75.`;

    const response = await fetch('https://ai.gateway.lovable.dev/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${LOVABLE_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'google/gemini-2.5-flash',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.8,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('AI API error:', response.status, errorText);
      
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: 'Rate limit exceeded. Please try again later.' }), {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      
      if (response.status === 402) {
        return new Response(JSON.stringify({ error: 'AI credits depleted. Please add more credits.' }), {
          status: 402,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      throw new Error(`AI API error: ${response.status}`);
    }

    const data = await response.json();
    const content = data.choices[0].message.content;
    
    // Extract JSON from markdown code blocks if present
    let recipes;
    try {
      const jsonMatch = content.match(/```json\s*([\s\S]*?)\s*```/) || content.match(/\[[\s\S]*\]/);
      const jsonStr = jsonMatch ? (jsonMatch[1] || jsonMatch[0]) : content;
      recipes = JSON.parse(jsonStr.trim());
    } catch (parseError) {
      console.error('Failed to parse AI response:', content);
      throw new Error('Failed to parse recipe data from AI');
    }

    console.log('Successfully generated recipes:', recipes.length);

    return new Response(JSON.stringify({ recipes }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error in generate-recipes function:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});