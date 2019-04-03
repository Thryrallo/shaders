Shader "Thry/Fog"{
	Properties{
		[HideInInspector] shader_name("THRY's Fog Shader", Float) = 0
		_Color ("Color",Color) = (1,1,1,1)
		_MaxIntensity ("Max Intensity", Range(0, 1)) = 1
		_MinDistance("Min Distance", Float) = 1
		_MaxDistance("Max Distance", Float) = 10
	}

		CustomEditor "ThryEditor"
		SubShader
	{
		Tags {"RenderType" = "Transparent" "Queue" = "Transparent+1500"}
		ZWrite Off
		ZTest Always
		Blend SrcAlpha OneMinusSrcAlpha

		GrabPass { "_BgTexFog" }

		Pass
		{
			Cull Off

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
				float4 grabPos : TEXCOORD2;
				float4 vertex : SV_POSITION;
				float4 projPos : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};
			
			float4 _Color;
			float _MaxIntensity;
			float _MinDistance;
			float _MaxDistance;

			sampler2D_float _BgTexFog;

			v2f vert(appdata v)
			{
				v2f o;
				float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.ray = worldPos.xyz - _WorldSpaceCameraPos;
				o.vertex = mul(UNITY_MATRIX_VP, worldPos);
				o.projPos = ComputeScreenPos(o.vertex);
				o.projPos.z = -mul(UNITY_MATRIX_V, worldPos).z;
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			fixed4 frag(v2f i) : SV_Target
			{
				float4 bgColor = tex2Dproj(_BgTexFog, i.grabPos);

				float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float3 worldPosition = sceneDepth * i.ray / i.projPos.z + _WorldSpaceCameraPos;

				float dis = max(_MinDistance, distance(worldPosition, _WorldSpaceCameraPos))- _MinDistance;
				float lerpVal = min(_MaxIntensity,_MaxIntensity*( dis / _MaxDistance));

				float3 newColor = lerp(bgColor, _Color.rgb, lerpVal);


				return float4(newColor, 1);
			}
			ENDCG
		}
	}
}
