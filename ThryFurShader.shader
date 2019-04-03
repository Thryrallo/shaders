// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Thry/Fur"
{
	Properties{
		[HideInInspector] shader_name("THRY's Fur Shader V0.1", Float) = 0
		[HideInInspector] m_mainOptions("Main Options", Float) = 0
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Color("Color", color) = (1,1,1,0)
		_BrightnessMulti("Shadow Baked",Range(0,1)) = 0

		/*[HideInInspector] m_start_emissionOptions("Emission Options", Float) = 0
		_EmissionColor("Emission Color",color) = (1,1,1,1)
		_EmissionStrength("Emission Strength",Float) = 0
		[HideInInspector] m_end_emissionOptions("Emission Options", Float) = 0*/

		[HideInInspector] m_furOptions("Fur Options", Float) = 0
		_DispTex("Disp Texture", 2D) = "gray" {}
		_Displacement("Displacement", Range(0, 1.0)) = 0.3
		_FurTex("Fur Texture", 2D) = "black" {}
		_FurTexIntensity("Fur Texture Intensity", Range(0,1)) = 0.5
		_Tess("Tessellation", Range(1,32)) = 4
		
		//[HideInInspector] m_emissionOptions("Emission Options", Float) = 0
		//_EmissionColor("Emission Color",color) = (1,1,1,1)
		//_EmissionStrength("Emission Strength",Float) = 0

		//[HideInInspector] m_blendOptions("Blend Options", Float) = 0
		//_StartBlendIn("Start Blend In",Float)=0
		//_EndBlendIn("Finish Blend In",Float) = 0
		
		[HideInInspector] m_colorChangeOptions("Color Change Options", Float) = 0
		_CycleYOffset("Cycle Y Offset",Float)=0
		_CycleTime("Cycle Time",Float) = 10
		_ColorCount("Color Count",Float) = 0
		_Color1("Color 1",Color) = (1, 1, 1, 1)
		_Color2("Color 2",Color) = (1, 1, 1, 1)
		_Color3("Color 3",Color) = (1, 1, 1, 1)
		_Color4("Color 4",Color) = (1, 1, 1, 1)
	}

	CustomEditor "ThryEditor"

	SubShader{
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		
		LOD 300

		Cull Off
		ZWrite On

		CGPROGRAM
		#pragma surface surf CelShadingFlatLitToon addshadow fullforwardshadows novertexlights nolightmap 

		uniform float _MinBrightness;
		uniform float _MaxBrightness;
		uniform float _BrightnessMulti;
		uniform float _ShadowEdge;

		half4 LightingCelShadingFlatLitToon(SurfaceOutput s, half3 lightDir, half atten) {
			half4 c;
			float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
			float3 reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;

			float3 directLighting = saturate((ShadeSH9(half4(0.0, 1.0, 0.0, 1.0)) + reflectionMap + _LightColor0.rgb*atten));
			float3 indirectLighting = saturate((ShadeSH9(half4(0.0, -1.0, 0.0, 1.0)) + reflectionMap));
			float lightContribution = dot(normalize(_WorldSpaceLightPos0.xyz - objPos), s.Normal)*atten;
			float directContribution = saturate((1.0 - _BrightnessMulti));
			float3 finalColor = s.Albedo * (lerp(indirectLighting, directLighting, directContribution));
			c.rgb = finalColor;
			c.a = s.Alpha;
			return c;
		}

		sampler2D _MainTex;

		uniform float4 _Color;

		uniform float _CycleTime;
		uniform float _ColorCount;
		uniform float4 _Color1;
		uniform float4 _Color2;
		uniform float4 _Color3;
		uniform float4 _Color4;

		float _CycleYOffset;

		float _StartBlendIn;
		float _EndBlendIn;

		sampler2D _CameraDepthTexture;

		bool IsInMirror()
		{
			return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
		}

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float4 screenPos;
		};
		// Green front faces
		void surf(Input IN, inout SurfaceOutput o) {

			half4 c = tex2D(_MainTex, IN.uv_MainTex)*_Color;
			float3 localPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

			if (_ColorCount > 0) {

				float time = fmod(((-localPos.y + _CycleYOffset) * 5) + _Time.g, (_CycleTime*_ColorCount));

				float3 finalColor = _Color1.rgb;
				float beforeColorTime = 0;

				float3 beforeColor = _Color1.rgb;
				if (_ColorCount > 3) { beforeColor = _Color4.rgb; }
				else if (_ColorCount > 2) { beforeColor = _Color3.rgb; }
				else if (_ColorCount > 1) { beforeColor = _Color2.rgb; }

				float3 afterColor = _Color1.rgb;
				if (_ColorCount > 1) { afterColor = _Color2.rgb; }


				if (_ColorCount > 3 && time > _CycleTime * 3) {
					//if time slot of color 4
					finalColor = _Color4.rgb;
					beforeColorTime = _CycleTime * 3;
					beforeColor = _Color3.rgb;
					afterColor = _Color1.rgb;
				}
				else if (_ColorCount > 2 && time > _CycleTime * 2) {
					//if time slot of color 3
					finalColor = _Color3.rgb;
					beforeColorTime = _CycleTime * 2;
					beforeColor = _Color2.rgb;
					afterColor = _Color1.rgb;
					if (_ColorCount > 3) { afterColor = _Color4.rgb; }
				}
				else if (_ColorCount > 1 && time > _CycleTime) {
					//if time slot of color 2
					finalColor = _Color2.rgb;
					beforeColorTime = _CycleTime;
					beforeColor = _Color1.rgb;
					afterColor = _Color1.rgb;
					if (_ColorCount > 2) { afterColor = _Color3.rgb; }
				}
				//blending the colors
				if (time - beforeColorTime < 1) {
					finalColor = lerp(beforeColor, finalColor, (time - beforeColorTime) / 2 + 0.5);
				}
				else if (time - beforeColorTime > _CycleTime - 1) {
					finalColor = lerp(finalColor, afterColor, (time - beforeColorTime - _CycleTime + 1) / 2);
				}
				o.Albedo = c * finalColor;
			}else{o.Albedo = c;}

			//float blendValue = clamp(1 / (_EndBlendIn - _StartBlendIn)*(localPos.y - _StartBlendIn), 0, 1);

			//cool code that makes bleding
			/*float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float surfZ = -mul(UNITY_MATRIX_V, float4(IN.worldPos.xyz, 1)).z;
			float diff = sceneZ - surfZ;
			float intersect = 1 - saturate(diff / _StartBlendIn);
			if (_EndBlendIn > localPos.y|| IsInMirror()) { intersect = 0; }

			o.Alpha = lerp(0, 1, 1 - intersect);*/
			o.Alpha = 1;
		}
		ENDCG

		Cull Back

		CGPROGRAM
		#pragma surface surf CelShadingFlatLitToon vertex:disp tessellate:tessFixed alpha:fade addshadow fullforwardshadows novertexlights nolightmap

		uniform float _MinBrightness;
		uniform float _MaxBrightness;
		uniform float _BrightnessMulti;
		uniform float _ShadowEdge;

		half4 LightingCelShadingFlatLitToon(SurfaceOutput s, half3 lightDir, half atten) {
			half4 c;
			float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
			float3 reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;

			float3 directLighting = saturate((ShadeSH9(half4(0.0, 1.0, 0.0, 1.0)) + reflectionMap + _LightColor0.rgb*atten));
			float3 indirectLighting = saturate((ShadeSH9(half4(0.0, -1.0, 0.0, 1.0)) + reflectionMap));
			float lightContribution = dot(normalize(_WorldSpaceLightPos0.xyz - objPos), s.Normal)*atten;
			float directContribution = saturate((1.0 - _BrightnessMulti) );
			float3 finalColor = s.Albedo * (lerp(indirectLighting, directLighting, directContribution));
			c.rgb = finalColor;
			c.a = s.Alpha;
			return c;
		}

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		float _Tess;

		float4 tessFixed()
		{
			return _Tess;
		}

		sampler2D _DispTex;
		float _Displacement;

		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldPos;
			float4 screenPos;
		};

		void disp(inout appdata v)
		{
			float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
			v.vertex.xyz += v.normal * d;
		}

		sampler2D _MainTex;
		sampler2D _FurTex;
		float _FurTexIntensity;
		fixed4 _Color;

		uniform float _CycleTime;
		uniform float _ColorCount;
		uniform float4 _Color1;
		uniform float4 _Color2;
		uniform float4 _Color3;
		uniform float4 _Color4;

		float _CycleYOffset;

		float _StartBlendIn;
		float _EndBlendIn;

		sampler2D _CameraDepthTexture;
		sampler2D _BgTex;

		bool IsInMirror()
		{
			return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
		}

		void surf(Input IN, inout SurfaceOutput o) {

			half4 c = (tex2D(_MainTex, IN.uv_MainTex)+tex2D(_FurTex,IN.uv_MainTex)*_FurTexIntensity)*_Color;
			float3 localPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

			if (_ColorCount > 0) {

				float time = fmod(((-localPos.y + _CycleYOffset) * 5) + _Time.g, (_CycleTime*_ColorCount));

				float3 finalColor = _Color1.rgb;
				float beforeColorTime = 0;

				float3 beforeColor = _Color1.rgb;
				if (_ColorCount > 3) { beforeColor = _Color4.rgb; }
				else if (_ColorCount > 2) { beforeColor = _Color3.rgb; }
				else if (_ColorCount > 1) { beforeColor = _Color2.rgb; }

				float3 afterColor = _Color1.rgb;
				if (_ColorCount > 1) { afterColor = _Color2.rgb; }


				if (_ColorCount > 3 && time > _CycleTime * 3) {
					//if time slot of color 4
					finalColor = _Color4.rgb;
					beforeColorTime = _CycleTime * 3;
					beforeColor = _Color3.rgb;
					afterColor = _Color1.rgb;
				}
				else if (_ColorCount > 2 && time > _CycleTime * 2) {
					//if time slot of color 3
					finalColor = _Color3.rgb;
					beforeColorTime = _CycleTime * 2;
					beforeColor = _Color2.rgb;
					afterColor = _Color1.rgb;
					if (_ColorCount > 3) { afterColor = _Color4.rgb; }
				}
				else if (_ColorCount > 1 && time > _CycleTime) {
					//if time slot of color 2
					finalColor = _Color2.rgb;
					beforeColorTime = _CycleTime;
					beforeColor = _Color1.rgb;
					afterColor = _Color1.rgb;
					if (_ColorCount > 2) { afterColor = _Color3.rgb; }
				}
				//blending the colors
				if (time - beforeColorTime < 1) {
					finalColor = lerp(beforeColor, finalColor, (time - beforeColorTime) / 2 + 0.5);
				}
				else if (time - beforeColorTime > _CycleTime - 1) {
					finalColor = lerp(finalColor, afterColor, (time - beforeColorTime - _CycleTime + 1) / 2);
				}
				o.Albedo = c * finalColor;
			}
			else { o.Albedo = c; }

			half rim = pow(1.0 - saturate(dot(normalize(IN.viewDir), o.Normal)),6);

			//float blendValue = clamp(1 / (_EndBlendIn - _StartBlendIn)*(localPos.y - _StartBlendIn),0,1);

			o.Specular = 0;
			o.Gloss = 0;
			o.Emission = 0;

			//cool code that makes bleding
			
			/*float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float surfZ = -mul(UNITY_MATRIX_V, float4(IN.worldPos.xyz, 1)).z;
			float diff = sceneZ - surfZ;
			float intersect = 1 - saturate(diff / _StartBlendIn);
			if ( IsInMirror()) { intersect = 0; }*/

			//o.Alpha = lerp(0,1-rim, 1-intersect);
			//o.Albedo = lerp(o.Albedo, float3(1, 1, 1), intersect);
			o.Alpha = 1-rim;
		}
		ENDCG

	}
	FallBack "Diffuse"
}