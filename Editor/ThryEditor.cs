//original code from poiyomi
//Generalized by Thryrallo

using System.Collections.Generic;
using System.Text.RegularExpressions;
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

        public static PoiToonHeader Foldout(ShaderHeader header)
        {
            var style = new GUIStyle("ShurikenModuleTitle");
            style.font = new GUIStyle(EditorStyles.label).font;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = 22;
            style.contentOffset = new Vector2(20f, -2f);
            style.margin.left = 30 * header.xOffset;

            var rect = GUILayoutUtility.GetRect(16f + 20f, 22f, style);
            GUI.Box(rect, header.name, style);

            var e = Event.current;

            var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, header.header.getState(), false);
            }

            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                header.header.Toggle();
                e.Use();
            }

            return header.header;
        }
    }

    GUIStyle m_sectionStyle;

    private class ShaderPart
    {
        public int xOffset = 0;
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

        public ShaderHeader(MaterialProperty prop, MaterialEditor materialEditor, int xOffset) : this(prop,materialEditor)
        {
            this.xOffset = xOffset;
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

        public ShaderProperty(MaterialProperty materialProperty, int xOffset) : this(materialProperty)
        {
            this.xOffset = xOffset;
        }
    }

    ShaderHeader shaderparts;

    public static int propertyOptionToInt(string optionName,string name)
    {
        string pattern = @"-"+ optionName + "=\\d+";
        Match match = Regex.Match(name, pattern);
        if (match.Success) {
            int ret = 0;
            string value = match.Value.Replace("-" + optionName+"=", "");
            int.TryParse(value, out ret);
            return ret;
        }
        return 0;
    }


    private void CollectAllProperties(MaterialProperty[] props, MaterialEditor materialEditor)
    {
        shaderparts = new ShaderHeader(null);
        Stack<ShaderHeader> headerStack = new Stack<ShaderHeader>();
        headerStack.Push(shaderparts);
        headerStack.Push(shaderparts);
        int headerCount = 0;
        for (int i = 0; i < props.Length; i++)
        {
            //Debug.Log("Name: "+ props[i].name +",Display Name: " +props[i].displayName+ ",flags: "+ props[i].flags+",type: "+props[i].type);
            if (props[i].name.StartsWith("m_end") && props[i].flags == MaterialProperty.PropFlags.HideInInspector)
            {
                headerStack.Pop();
                headerCount--;
            }
            else if (props[i].name.StartsWith("m_start") && props[i].flags == MaterialProperty.PropFlags.HideInInspector)
            {
                //Debug.Log("Header: " + props[i].displayName);
                headerCount++;
                ShaderHeader newHeader = new ShaderHeader(props[i], materialEditor, headerCount);
                headerStack.Peek().addPart(newHeader);
                headerStack.Push(newHeader);
            }
            else if (props[i].name.StartsWith("m_") && props[i].flags == MaterialProperty.PropFlags.HideInInspector)
            {
                //Debug.Log("Header: " + props[i].displayName);
                ShaderHeader newHeader = new ShaderHeader(props[i], materialEditor, headerCount);
                headerStack.Pop();
                headerStack.Peek().addPart(newHeader);
                headerStack.Push(newHeader); 
            }
            else if (props[i].flags != MaterialProperty.PropFlags.HideInInspector)
            {
                //Debug.Log("Property: " + props[i].displayName);
                int extraOffset = 0;
                extraOffset = propertyOptionToInt("extraOffset",props[i].displayName);
                ShaderProperty newPorperty = new ShaderProperty(props[i], headerCount+ extraOffset);
                headerStack.Peek().addPart(newPorperty);
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
        header.header = PoiToonUI.Foldout(header);
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
        //materialEditor.ShaderProperty(property.materialProperty, property.style);
        materialEditor.ShaderProperty(property.materialProperty, property.style.text, property.xOffset*2+1);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        Material material = materialEditor.target as Material;

        CollectAllProperties(props, materialEditor);

        // load default toggle values
        LoadDefaults(material);

        DrawMasterLabel(FindProperty("shader_name", props).displayName);

        foreach (ShaderPart part in shaderparts.parts)
        {
            drawShaderPart(part, materialEditor);
        }

        ToggleDefines(material);
    }
}
