//original code from poiyomi
//Generalized by Thryrallo

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ThryEditor : ShaderGUI
{

    private class PoiToonHeader
    {
        private List<MaterialProperty> propertyes;
        private bool currentState;

        public PoiToonHeader(MaterialEditor materialEditor, string propertyName)
        {
            this.propertyes = new List<MaterialProperty>();
            foreach (Material materialEditorTarget in materialEditor.targets)
            {
                Object[] asArray = new Object[] { materialEditorTarget };
                propertyes.Add(MaterialEditor.GetMaterialProperty(asArray, propertyName));
            }

            this.currentState = fetchState();
        }

        public bool fetchState()
        {
            foreach (MaterialProperty materialProperty in propertyes)
            {
                if (materialProperty.floatValue == 1)
                    return true;
            }



            return false;
        }

        public bool getState()
        {
            return this.currentState;
        }

        public void Toggle()
        {

            if (getState())
            {
                foreach (MaterialProperty materialProperty in propertyes)
                {
                    materialProperty.floatValue = 0;
                }
            }
            else
            {
                foreach (MaterialProperty materialProperty in propertyes)
                {
                    materialProperty.floatValue = 1;
                }
            }

            this.currentState = !this.currentState;
        }
    }

    private static class PoiToonUI
    {
        public static PoiToonHeader Foldout(string title, PoiToonHeader display)
        {
            var style = new GUIStyle("ShurikenModuleTitle");
            style.font = new GUIStyle(EditorStyles.label).font;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = 22;
            style.contentOffset = new Vector2(20f, -2f);

            var rect = GUILayoutUtility.GetRect(16f, 22f, style);
            GUI.Box(rect, title, style);

            var e = Event.current;

            var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, display.getState(), false);
            }

            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                display.Toggle();
                e.Use();
            }

            return display;
        }
    }

    GUIStyle m_sectionStyle;

    private class ShaderPart
    {

    }

    private class ShaderHeader : ShaderPart
    {
        public PoiToonHeader header;
        public List<ShaderPart> parts = new List<ShaderPart>();
        public string name;

        public ShaderHeader(PoiToonHeader header)
        {
            this.header = header;
        }

        public ShaderHeader(MaterialProperty prop, MaterialEditor materialEditor)
        {
            this.header = new PoiToonHeader(materialEditor, prop.name); ;
            this.name = prop.displayName;
        }

        public void addPart(ShaderPart part)
        {
            parts.Add(part);
        }
    }

    private class ShaderProperty : ShaderPart
    {
        public MaterialProperty materialProperty;
        public GUIContent style;


        public ShaderProperty(MaterialProperty materialProperty, GUIContent style)
        {
            this.materialProperty = materialProperty;
            this.style = style;
        }

        public ShaderProperty(MaterialProperty materialProperty)
        {
            this.materialProperty = materialProperty;
            this.style = new GUIContent(materialProperty.displayName, materialProperty.name + materialProperty.type);
        }
    }

    List<ShaderPart> shaderparts;

    private void CollectAllProperties(MaterialProperty[] props, MaterialEditor materialEditor)
    {
        shaderparts = new List<ShaderPart>();
        ShaderHeader currentHeader = null;
        for (int i = 0; i < props.Length; i++)
        {
            //Debug.Log("Name: "+ props[i].name +",Display Name: " +props[i].displayName+ ",flags: "+ props[i].flags+",type: "+props[i].type);
            if (props[i].name.StartsWith("m_") && props[i].flags == MaterialProperty.PropFlags.HideInInspector)
            {
                //Debug.Log("Header: " + props[i].displayName);
                ShaderHeader newHeader = new ShaderHeader(props[i], materialEditor);
                currentHeader = newHeader;
                shaderparts.Add(currentHeader);
            }
            else if (props[i].flags != MaterialProperty.PropFlags.HideInInspector)
            {
                //Debug.Log("Property: " + props[i].displayName);
                ShaderProperty newPorperty = new ShaderProperty(props[i]);
                if (currentHeader != null) { currentHeader.addPart(newPorperty); }
                else { shaderparts.Add(newPorperty); }
            }

        }
    }

    private void SetupStyle()
    {
        m_sectionStyle = new GUIStyle(EditorStyles.boldLabel);
        m_sectionStyle.alignment = TextAnchor.MiddleCenter;
    }

    private void ToggleDefine(Material mat, string define, bool state)
    {
        if (state)
        {
            mat.EnableKeyword(define);
        }
        else
        {
            mat.DisableKeyword(define);
        }
    }

    void ToggleDefines(Material mat)
    {
    }

    void LoadDefaults(Material mat)
    {
    }

    void DrawHeader(ref bool enabled, ref bool options, GUIContent name)
    {
        var r = EditorGUILayout.BeginHorizontal("box");
        enabled = EditorGUILayout.Toggle(enabled, EditorStyles.radioButton, GUILayout.MaxWidth(15.0f));
        options = GUI.Toggle(r, options, GUIContent.none, new GUIStyle());
        EditorGUILayout.LabelField(name, m_sectionStyle);
        EditorGUILayout.EndHorizontal();
    }

    void DrawMasterLabel(string shaderName)
    {
        GUIStyle style = new GUIStyle(GUI.skin.label);
        style.richText = true;
        style.alignment = TextAnchor.MiddleCenter;

        EditorGUILayout.LabelField("<size=18><color=#00339B>" + shaderName + " </color></size>", style, GUILayout.MinHeight(16));
    }

    void drawShaderPart(ShaderPart part, MaterialEditor materialEditor)
    {
        if (part is ShaderHeader)
        {
            ShaderHeader header = (ShaderHeader)part;
            drawShaderHeader(header, materialEditor);
        }
        else
        {
            ShaderProperty property = (ShaderProperty)part;
            drawShaderProperty(property, materialEditor);
        }
    }

    void drawShaderHeader(ShaderHeader header, MaterialEditor materialEditor)
    {
        header.header = PoiToonUI.Foldout(header.name, header.header);
        if (header.header.getState())
        {
            EditorGUILayout.Space();
            foreach (ShaderPart part in header.parts)
            {
                drawShaderPart(part, materialEditor);
            }
            EditorGUILayout.Space();
        }
    }

    void drawShaderProperty(ShaderProperty property, MaterialEditor materialEditor)
    {
        materialEditor.ShaderProperty(property.materialProperty, property.style);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        Material material = materialEditor.target as Material;

        CollectAllProperties(props, materialEditor);

        // load default toggle values
        LoadDefaults(material);

        DrawMasterLabel(FindProperty("shader_name", props).displayName);

        foreach (ShaderPart part in shaderparts)
        {
            drawShaderPart(part, materialEditor);
        }

        ToggleDefines(material);
    }
}
