Shader "Thry/Brightness"
{
	Properties
	{
		[HideInInspector] shader_name("THRY's Brightness Shader", Float) = 0
		_IntensityValue("Intensity", Float) = 1
		_BrightnessAlgoritm("BrightnessAlgoritm",Int)=0
		
		[HideInInspector] m_start_renderTexOptions("Render texture Options", Float) = 0
		[MaterialToggle] _UseBrightnessTexture("Controll brightness through render texture",Float) = 0
		_BrightnessTexture("Brightness Texture (r value) -extraOffset=1", 2D) = "white" {}
		[MaterialToggle] _UseBrightnessAlgoTexture("Control algotrithm through render texture",Float) = 0
		_BrightnessAlgoritmTexture("Brightness Algo Texture (r value) -extraOffset=1",2D) = "black"{}
		[HideInInspector] m_end_renderTexOptions("Render texture Options", Float) = 0
		[MaterialToggle] _KeepBlack("Keep Blackness",Float) = 0
	}

	CustomEditor "ThryEditor"
	
	SubShader
	{
		Tags {"RenderType"="Transparent" "Queue"="Transparent+2000"}
		ZWrite Off
		ZTest Always
		Blend SrcAlpha OneMinusSrcAlpha

		GrabPass { "_BgTexEffectsShader" }

		Pass
		{
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 grabPos : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			bool IsInMirror()
			{
				return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
			}

			float _IntensityValue;
			int _BrightnessAlgoritm;

			float _UseBrightnessTexture;
			sampler2D _BrightnessTexture;
			
			float _UseBrightnessAlgoTexture;
			sampler2D _BrightnessAlgoritmTexture;

			float _KeepBlack;

			sampler2D_float _BgTexEffectsShader;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 bgColor = tex2Dproj(_BgTexEffectsShader, i.grabPos);

				//get intensity
				float intensity = 1;
				if (_UseBrightnessTexture == 1) {
					intensity = tex2D(_BrightnessTexture, float2(0.5, 0.5)).r;
					intensity = 2 * intensity;
					if (intensity == 0) { intensity = 1; }
				}
				else {
					intensity = _IntensityValue;
				}

				//modify intensity curve
				if (intensity <= 1) {
					intensity = 0.9*pow(intensity, 5)+0.1*intensity+0.002;
				}
				else if (intensity > 1) {
					intensity = pow(intensity-1, 2.5)+1;
				}

				//init maxRGB and multiplier
				float maxRGB = max(bgColor.r, max(bgColor.g, bgColor.b));
				float multiplier = 1;

				// get algorythm
				int algo = 0;
				if (_UseBrightnessAlgoTexture == 1) {
					int algoCount = 3;
					algo = floor((algoCount-1)*tex2D(_BrightnessAlgoritmTexture, float2(0.5, 0.5)).r+0.5);
				}
				else {
					algo = _BrightnessAlgoritm;
				}

				//apply algorithm
				if (algo == 0) {
					multiplier = intensity;
					if (IsInMirror()) { multiplier = 1; }
				}
				else if (algo == 1) {
					multiplier = intensity;
					if (intensity <= 1) {
						multiplier *= 1 / (1 + maxRGB);
					}
					else {
						multiplier *= 1 + maxRGB;
					}
					if (IsInMirror()) { multiplier = 1; }
				}
				else if (algo == 2) {
					if (intensity <= 1) {
						multiplier = min(intensity / maxRGB, 1);
					}
					else {
						intensity = 2 * (intensity - 1);
						multiplier = max(1, intensity / maxRGB);
						if (maxRGB < 0.0008) {
							multiplier = 1;
							if (!_KeepBlack) { bgColor = float4(intensity, intensity, intensity, 1); }
						}
					}
				}

				//get final color
				float3 newColor = bgColor*multiplier;
				

				return float4(newColor, 1);
			}
			ENDCG
		}

		Pass
		{
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 grabPos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _BgTexEffectsShader;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 bgColor = tex2Dproj(_BgTexEffectsShader, i.grabPos);

				float3 newColor = bgColor;

				return float4(newColor, 1);
			}
			ENDCG
		}
	}
}
