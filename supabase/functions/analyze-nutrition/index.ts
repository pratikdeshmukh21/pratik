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
    const { recipe } = await req.json();
    console.log('Analyzing nutrition for recipe:', recipe.name);

    const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');
    if (!LOVABLE_API_KEY) {
      throw new Error('LOVABLE_API_KEY is not configured');
    }

    const systemPrompt = `You are an expert AI nutritionist specializing in comprehensive health analysis.
Analyze the given recipe and provide detailed health insights.

Return ONLY a valid JSON object with this exact structure:
{
  "health_score": 85,
  "weight_loss_compatible": true,
  "diabetic_friendly": true,
  "allergy_risks": ["dairy", "nuts"],
  "health_benefits": ["High in protein", "Rich in fiber", "Good source of vitamins"],
  "concerns": ["High in sodium"],
  "recommendations": "Reduce salt content by 50% for better heart health."
}`;

    const userPrompt = `Analyze this recipe:
Name: ${recipe.name}
Ingredients: ${JSON.stringify(recipe.ingredients)}
Nutrition: ${JSON.stringify(recipe.nutrition)}
Dietary Tags: ${recipe.dietary_tags?.join(', ') || 'None'}

Provide a comprehensive health analysis including:
- Health score (0-100)
- Weight loss compatibility (boolean)
- Diabetic-friendly status (boolean)
- Potential allergy risks (array)
- Key health benefits (array)
- Any health concerns (array)
- Recommendations for improvement (string)`;

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
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('AI API error:', response.status, errorText);
      throw new Error(`AI API error: ${response.status}`);
    }

    const data = await response.json();
    const content = data.choices[0].message.content;
    
    // Extract JSON from markdown code blocks if present
    let analysis;
    try {
      const jsonMatch = content.match(/```json\s*([\s\S]*?)\s*```/) || content.match(/\{[\s\S]*\}/);
      const jsonStr = jsonMatch ? (jsonMatch[1] || jsonMatch[0]) : content;
      analysis = JSON.parse(jsonStr.trim());
    } catch (parseError) {
      console.error('Failed to parse AI response:', content);
      throw new Error('Failed to parse nutrition analysis from AI');
    }

    console.log('Successfully analyzed nutrition');

    return new Response(JSON.stringify(analysis), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error in analyze-nutrition function:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});