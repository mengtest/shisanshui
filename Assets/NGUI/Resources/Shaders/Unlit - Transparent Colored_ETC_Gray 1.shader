﻿Shader "Hidden/Unlit/Transparent Colored_ETC_Gray 1"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "black" {}
		_AlphaTex ("Alpha Tex (R)", 2D) = "black" {}
	}

	SubShader
	{
		LOD 200

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Offset -1, -1
			Fog { Mode Off }			
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			float4 _ClipRange0 = float4(0.0, 0.0, 1.0, 1.0);
			float4 _ClipArgs0 = float4(1000.0, 1000.0, 0.0, 1.0);

			struct appdata_t
			{
				float4 vertex : POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 worldPos : TEXCOORD1;
			};

			v2f o;
			
			float2 Rotate (float2 v, float2 rot)
			{
				float2 ret;
				ret.x = v.x * rot.y - v.y * rot.x;
				ret.y = v.x * rot.x + v.y * rot.y;
				return ret;
			}

			v2f vert (appdata_t v)
			{
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.color;
				o.texcoord = v.texcoord;
				float2 pos = (ComputeScreenPos(o.vertex).xy - float2(0.5, 0.5)) * _ScreenParams.xy;
				pos = Rotate(pos - _ClipRange0.xy, _ClipArgs0.zw);
 				o.worldPos = pos * _ClipRange0.zw;   
				return o;
			}

			half4 frag (v2f IN) : SV_Target
			{
				// Softness factor
				float2 factor = (float2(1.0, 1.0) - abs(IN.worldPos)) * _ClipArgs0;
			
				// Sample the texture
				half4 col;
				col.rgb = tex2D(_MainTex, IN.texcoord).rgb * IN.color.rgb;
				col.a = tex2D(_AlphaTex, IN.texcoord).r*IN.color.a;
				col.a *= clamp( min(factor.x, factor.y), 0.0, 1.0);
				
				half g=0.299*col.r+0.587*col.g+0.184*col.b;
				col.r=col.g=col.b=g;
				
				return col;
			}
			ENDCG
		}
	}
}
