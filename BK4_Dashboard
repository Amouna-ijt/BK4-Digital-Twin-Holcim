using UnityEngine;
using System.Collections.Generic;

public class BK4_Dashboard : MonoBehaviour
{
    [Header("=== CONNEXION ===")]
    public SimulinkReceiver receiver;

    [Header("=== SEUILS MOTEUR ===")]
    public float bobine_alarme = 100f;
    public float bobine_arret = 120f;
    public float palier_mot_alarme = 85f;
    public float palier_mot_arret = 95f;
    public float vib_mot_alarme = 6.5f;
    public float vib_mot_arret = 7.1f;

    [Header("=== SEUILS REDUCTEUR ===")]
    public float palier_red_alarme = 70f;
    public float palier_red_arret = 75f;
    public float huile_alarme = 70f;
    public float huile_arret = 75f;
    public float vib_red_alarme = 4f;
    public float vib_red_arret = 5f;

    [Header("=== SEUILS PRESSION ===")]
    public float p_hydr_alarme = 200f;
    public float p_hydr_arret = 250f;
    public float p_pompe_alarme =200f;
    public float p_pompe_arret = 250f;
    public float contre_p_alarme = 150f;
    public float contre_p_arret = 200f;

    private float proba_moteur, proba_reducteur;
    private string etat_global = "SAIN";
    private float blinkTimer = 0f;
    private bool blinkOn = true;
    private Vector2 scrollPos = Vector2.zero;

    private const int HIST_MAX = 600;
    private float histTimer = 0f;
    private Dictionary<string, List<float>> historique = new Dictionary<string, List<float>>();
    private string courbeActive = "";
    private float zoomCourbe = 1f;

    private GUIStyle sH, sT, sL, sV, sS, sC;
    private bool stylesOK = false;

    private Color CYAN_VIF = new Color(0f, 0.85f, 0.85f);
    private Color CYAN_FONCE = new Color(0f, 0.5f, 0.55f);
    private Color VERDEAU = new Color(0.1f, 0.75f, 0.65f);
    private Color BLANC = new Color(0.92f, 0.94f, 0.96f);
    private Color GRIS = new Color(0.55f, 0.6f, 0.65f);
    private Color GRIS_CLAIR = new Color(0.72f, 0.75f, 0.78f);
    private Color VERT = new Color(0.18f, 0.8f, 0.35f);
    private Color ORANGE = new Color(0.95f, 0.65f, 0.1f);
    private Color ROUGE = new Color(0.92f, 0.25f, 0.25f);
    private Color FOND = new Color(0.06f, 0.1f, 0.14f, 0.96f);
    private Color FOND2 = new Color(0.08f, 0.14f, 0.18f, 0.97f);
    private Color FOND3 = new Color(0.1f, 0.17f, 0.22f, 0.97f);
    private Color LIGNE = new Color(0.15f, 0.25f, 0.3f);
    private Color BLEU = new Color(0.2f, 0.5f, 0.9f);
    private Color VIOLET = new Color(0.6f, 0.3f, 0.9f);

    private Texture2D tFond, tFond2, tFond3, tLigne, tBar;
    private Texture2D tVert, tOrange, tRouge, tCyan, tVerdeau, tBleu, tBlanc, tViolet;

    void Start()
    {
        tFond = Tx(FOND); tFond2 = Tx(FOND2); tFond3 = Tx(FOND3);
        tLigne = Tx(LIGNE); tBar = Tx(new Color(0.12f, 0.2f, 0.25f));
        tVert = Tx(VERT); tOrange = Tx(ORANGE); tRouge = Tx(ROUGE);
        tCyan = Tx(CYAN_VIF); tVerdeau = Tx(VERDEAU); tBleu = Tx(BLEU);
        tBlanc = Tx(BLANC); tViolet = Tx(VIOLET);

        string[] noms = { "T Bob.R","T Bob.S","T Bob.T","T Pal.DE","T Pal.NDE","Vib.Mot",
            "T Pal.R1","T Pal.R2","T Huile","Vib.Red","Pos.Galet","V.Sep",
            "P.Trav G1","P.Trav G2","P.Pomp G1","P.Pomp G2","C.Pres G1","C.Pres G2" };
        foreach (string n in noms) historique[n] = new List<float>();
    }

    Texture2D Tx(Color c) { Texture2D t = new Texture2D(1, 1); t.SetPixel(0, 0, c); t.Apply(); return t; }
    Texture2D TxC(Color c) { if (c == VERT) return tVert; if (c == ORANGE) return tOrange; if (c == ROUGE) return tRouge; return tCyan; }

    void InitStyles()
    {
        if (stylesOK) return; stylesOK = true;
        sH = new GUIStyle(GUI.skin.label) { fontSize = 18, fontStyle = FontStyle.Bold }; sH.normal.textColor = CYAN_VIF;
        sT = new GUIStyle(GUI.skin.label) { fontSize = 12, fontStyle = FontStyle.Bold }; sT.normal.textColor = CYAN_VIF;
        sL = new GUIStyle(GUI.skin.label) { fontSize = 11 }; sL.normal.textColor = GRIS_CLAIR;
        sV = new GUIStyle(GUI.skin.label) { fontSize = 11, fontStyle = FontStyle.Bold }; sV.alignment = TextAnchor.MiddleRight;
        sS = new GUIStyle(GUI.skin.label) { fontSize = 10 }; sS.normal.textColor = GRIS;
        sC = new GUIStyle(GUI.skin.label) { fontSize = 10 }; sC.normal.textColor = BLANC;
    }

    void Update()
    {
        blinkTimer += Time.deltaTime;
        if (blinkTimer > 0.5f) { blinkTimer = 0; blinkOn = !blinkOn; }
        if (receiver == null) return;
        CalcProba();
        histTimer += Time.deltaTime;
        if (histTimer >= 1f)
        {
            histTimer = 0f;
            AH("T Bob.R", receiver.T_bobA); AH("T Bob.S", receiver.T_bobB); AH("T Bob.T", receiver.T_bobC);
            AH("T Pal.DE", receiver.T_pal_DE); AH("T Pal.NDE", receiver.T_pal_NDE); AH("Vib.Mot", receiver.vib_moteur);
            AH("T Pal.R1", receiver.T_pal1_red); AH("T Pal.R2", receiver.T_pal2_red); AH("T Huile", receiver.T_huile);
            AH("Vib.Red", receiver.vib_red); AH("Pos.Galet", receiver.pos_galet); AH("V.Sep", receiver.w_separateur);
            AH("P.Trav G1", receiver.P_hydr1); AH("P.Trav G2", receiver.P_hydr2);
            AH("P.Pomp G1", receiver.pression_pompe1); AH("P.Pomp G2", receiver.pression_pompe2);
            AH("C.Pres G1", receiver.contre_pression1); AH("C.Pres G2", receiver.contre_pression2);
        }
    }

    void AH(string n, float v) { if (!historique.ContainsKey(n)) historique[n] = new List<float>(); historique[n].Add(v); if (historique[n].Count > HIST_MAX) historique[n].RemoveAt(0); }

    struct JI { public string nom; public float val, alarme, arret; public string unite; }
    JI JJ(string n, float v, float a, float ar, string u) { return new JI { nom = n, val = v, alarme = a, arret = ar, unite = u }; }

    void OnGUI()
    {
        if (receiver == null) return;
        InitStyles();
        float W = 400, pX = Screen.width - W - 10, pH = Screen.height - 10;
        GUI.DrawTexture(new Rect(pX - 5, 2, W + 12, pH), tFond);
        scrollPos = GUI.BeginScrollView(new Rect(pX - 5, 2, W + 20, pH), scrollPos, new Rect(0, 0, W, 1600));
        float x = 5, y = 8;

        // TITRE
        GUI.Label(new Rect(x + 8, y, 300, 26), "SUPERVISION BROYEUR BK4", sH);
        if (receiver.etat_ia == 3)
            etat_global = "DANGER";
        else if (receiver.etat_ia == 2)
            etat_global = "ALARME";
        else
        {
            float maxP2 = Mathf.Max(proba_moteur, proba_reducteur);
            etat_global = maxP2 < 20f ? "SAIN" : maxP2 < 60f ? "ALARME" : "DANGER";
        }
        DrawBadge(x + W - 80, y + 3, etat_global);
        y += 30; GUI.DrawTexture(new Rect(x + 8, y, W - 16, 1), tLigne); y += 8;

        // MÉTRIQUES
        float mW = (W - 35) / 4, mG = 4;
        DrawMet(x + 8, y, mW, "MOTEUR", receiver.wm.ToString("F1"), "rad/s");
        DrawMet(x + 8 + (mW + mG), y, mW, "TABLE", receiver.w_table.ToString("F2"), "rad/s");
        DrawMet(x + 8 + (mW + mG) * 2, y, mW, "SEPAR.", receiver.w_separateur.ToString("F1"), "rad/s");
        DrawMet(x + 8 + (mW + mG) * 3, y, mW, "POS.GAL", receiver.pos_galet.ToString("F0"), "%");
        y += 50;

        // MOTEUR
        y = DrawSection(x + 6, y, W - 12, "MOTEUR PRINCIPAL", tCyan, new JI[] {
            JJ("T Bob.R", receiver.T_bobA, bobine_alarme, bobine_arret, "C"),
            JJ("T Bob.S", receiver.T_bobB, bobine_alarme, bobine_arret, "C"),
            JJ("T Bob.T", receiver.T_bobC, bobine_alarme, bobine_arret, "C"),
            JJ("T Pal.DE", receiver.T_pal_DE, palier_mot_alarme, palier_mot_arret, "C"),
            JJ("T Pal.NDE", receiver.T_pal_NDE, palier_mot_alarme, palier_mot_arret, "C"),
            JJ("Vib.Mot", receiver.vib_moteur, vib_mot_alarme, vib_mot_arret, "mm/s"),
        });

        // RÉDUCTEUR
        y = DrawSection(x + 6, y, W - 12, "REDUCTEUR", tVerdeau, new JI[] {
            JJ("T Pal.R1", receiver.T_pal1_red, palier_red_alarme, palier_red_arret, "C"),
            JJ("T Pal.R2", receiver.T_pal2_red, palier_red_alarme, palier_red_arret, "C"),
            JJ("T Huile", receiver.T_huile, huile_alarme, huile_arret, "C"),
            JJ("Vib.Red", receiver.vib_red, vib_red_alarme, vib_red_arret, "mm/s"),
        });

        // PRESSIONS
        y = DrawPress(x + 6, y, W - 12, "PRESSIONS GALET 1 (bar)",
            "P.Trav G1", receiver.P_hydr1, p_hydr_alarme, p_hydr_arret,
            "P.Pomp G1", receiver.pression_pompe1, p_pompe_alarme, p_pompe_arret,
            "C.Pres G1", receiver.contre_pression1, contre_p_alarme, contre_p_arret);
        y = DrawPress(x + 6, y, W - 12, "PRESSIONS GALET 2 (bar)",
            "P.Trav G2", receiver.P_hydr2, p_hydr_alarme, p_hydr_arret,
            "P.Pomp G2", receiver.pression_pompe2, p_pompe_alarme, p_pompe_arret,
            "C.Pres G2", receiver.contre_pression2, contre_p_alarme, contre_p_arret);

        // CLASSIFICATION IA
        y = DrawIA(x + 6, y, W - 12);

        // PRÉDICTIF RUL
        y = DrawRUL(x + 6, y, W - 12);

        // FIABILITÉ MTBF WEIBULL
        y = DrawFiab(x + 6, y, W - 12);

        // PROBABILITÉ DE PANNE
        y = DrawProbaSection(x + 6, y, W - 12);

        // TABLEAU
        y = DrawTableau(x + 6, y, W - 12);

        // ALERTES
        DrawAlertes(x + 6, y, W - 12);

        GUI.EndScrollView();
        if (courbeActive != "") DrawCourbe();
    }

    // ═══════════ BADGE ═══════════
    void DrawBadge(float x, float y, string etat)
    {
        Color c = etat == "SAIN" ? VERT : etat == "ALARME" ? ORANGE : ROUGE;
        GUI.DrawTexture(new Rect(x, y, 70, 18), Tx(new Color(c.r, c.g, c.b, 0.25f)));
        GUIStyle s = new GUIStyle(sS) { fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter, fontSize = 11 };
        s.normal.textColor = c; GUI.Label(new Rect(x, y, 70, 18), etat, s);
    }

    // ═══════════ MÉTRIQUE ═══════════
    void DrawMet(float x, float y, float w, string l, string v, string u)
    {
        GUI.DrawTexture(new Rect(x, y, w, 44), tFond2);
        GUIStyle ls = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 }; ls.normal.textColor = GRIS;
        GUI.Label(new Rect(x, y + 2, w, 12), l, ls);
        GUIStyle vs = new GUIStyle(sV) { fontSize = 15, alignment = TextAnchor.MiddleCenter }; vs.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(x, y + 13, w, 18), v, vs);
        ls.normal.textColor = GRIS; GUI.Label(new Rect(x, y + 32, w, 10), u, ls);
    }

    // ═══════════ SECTION JAUGES ═══════════
    float DrawSection(float x, float y, float w, string titre, Texture2D accent, JI[] jauges)
    {
        float h = 24 + jauges.Length * 20 + 8;
        GUI.DrawTexture(new Rect(x, y, w, h), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), accent);
        GUI.Label(new Rect(x + 16, y + 4, 200, 18), titre, sT);
        Color etat = VERT;
        foreach (var j in jauges) { Color c = GC(j.val, j.alarme, j.arret); if (c == ROUGE) etat = ROUGE; else if (c == ORANGE && etat != ROUGE) etat = ORANGE; }
        DrawMiniEtat(x + w - 62, y + 5, etat);
        y += 24;
        foreach (var j in jauges) { DrawJauge(x + 8, y, w - 16, j); y += 20; }
        return y + 8;
    }

    void DrawJauge(float x, float y, float w, JI j)
    {
        float lW = 82, vW = 62, bX = x + lW, bW = w - lW - vW - 4, bH = 7, bY = y + 5;
        Color c = GC(j.val, j.alarme, j.arret);
        if (GUI.Button(new Rect(x, y, w, 18), "", GUIStyle.none)) { courbeActive = (courbeActive == j.nom) ? "" : j.nom; zoomCourbe = 1f; }
        if (courbeActive == j.nom) GUI.DrawTexture(new Rect(x, y, w, 18), Tx(new Color(CYAN_VIF.r, CYAN_VIF.g, CYAN_VIF.b, 0.08f)));
        GUIStyle ls = new GUIStyle(sL); if (courbeActive == j.nom) ls.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(x, y, lW, 16), j.nom, ls);
        GUI.DrawTexture(new Rect(bX, bY, bW, bH), tBar);
        float nW = bW * Mathf.Clamp01(j.alarme / (j.arret * 1.3f));
        GUI.DrawTexture(new Rect(bX, bY, nW, bH), Tx(new Color(VERT.r, VERT.g, VERT.b, 0.12f)));
        float aW = bW * Mathf.Clamp01(j.arret / (j.arret * 1.3f)) - nW;
        GUI.DrawTexture(new Rect(bX + nW, bY, aW, bH), Tx(new Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.08f)));
        float pos = bX + bW * Mathf.Clamp01(j.val / (j.arret * 1.3f));
        GUI.DrawTexture(new Rect(pos - 1, bY - 2, 3, bH + 4), TxC(c));
        GUI.DrawTexture(new Rect(bX + nW, bY - 1, 1, bH + 2), tOrange);
        float mAr = bX + bW * Mathf.Clamp01(j.arret / (j.arret * 1.3f));
        GUI.DrawTexture(new Rect(mAr, bY - 1, 1, bH + 2), tRouge);
        sV.normal.textColor = c; GUI.Label(new Rect(x + w - vW, y, vW, 16), j.val.ToString("F1") + " " + j.unite, sV);
    }

    // ═══════════ PRESSIONS ═══════════
    float DrawPress(float x, float y, float w, string titre, string n1, float v1, float a1, float r1, string n2, float v2, float a2, float r2, string n3, float v3, float a3, float r3)
    {
        float h = 95; GUI.DrawTexture(new Rect(x, y, w, h), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), tBleu);
        GUI.Label(new Rect(x + 16, y + 4, 280, 18), titre, sT);
        y += 26; float gW = (w - 30) / 3;
        DrawJC(x + 8, y, gW, n1, v1, a1, r1); DrawJC(x + 8 + gW + 6, y, gW, n2, v2, a2, r2); DrawJC(x + 8 + (gW + 6) * 2, y, gW, n3, v3, a3, r3);
        return y + 68;
    }

    void DrawJC(float x, float y, float w, string nom, float val, float al, float ar)
    {
        Color c = GC(val, al, ar);
        if (GUI.Button(new Rect(x, y, w, 62), "", GUIStyle.none)) { courbeActive = (courbeActive == nom) ? "" : nom; zoomCourbe = 1f; }
        float arcH = 8, arcW = w - 10, arcX = x + 5, arcY = y + 28;
        GUI.DrawTexture(new Rect(arcX, arcY, arcW, arcH), tBar);
        GUI.DrawTexture(new Rect(arcX, arcY, arcW * Mathf.Clamp01(val / (ar * 1.3f)), arcH), TxC(c));
        GUI.DrawTexture(new Rect(arcX + arcW * Mathf.Clamp01(al / (ar * 1.3f)), arcY - 1, 1, arcH + 2), tOrange);
        GUI.DrawTexture(new Rect(arcX + arcW * Mathf.Clamp01(ar / (ar * 1.3f)), arcY - 1, 1, arcH + 2), tRouge);
        GUIStyle ns = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 8 }; ns.normal.textColor = GRIS_CLAIR;
        GUI.Label(new Rect(x, y, w, 14), nom, ns);
        GUIStyle vs = new GUIStyle(sV) { fontSize = 16, alignment = TextAnchor.MiddleCenter }; vs.normal.textColor = c; vs.fontStyle = FontStyle.Bold;
        GUI.Label(new Rect(x, y + 10, w, 20), val.ToString("F0"), vs);
        GUIStyle es = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 }; es.normal.textColor = c; es.fontStyle = FontStyle.Bold;
        GUI.Label(new Rect(x, y + 40, w, 14), c == VERT ? "OK" : c == ORANGE ? "ALARME" : "ARRET", es);
        GUIStyle us = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 }; us.normal.textColor = GRIS;
        GUI.Label(new Rect(x, y + 52, w, 12), "bar", us);
    }

    void DrawMiniEtat(float x, float y, Color c)
    {
        string t = c == VERT ? "NORMAL" : c == ORANGE ? "ALARME" : "DANGER";
        GUI.DrawTexture(new Rect(x, y, 54, 15), Tx(new Color(c.r, c.g, c.b, 0.2f)));
        GUIStyle s = new GUIStyle(sS) { fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter, fontSize = 9 };
        s.normal.textColor = c; GUI.Label(new Rect(x, y, 54, 15), t, s);
    }

    // ═══════════ CLASSIFICATION IA ═══════════
    float DrawIA(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 78), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), tViolet);
        GUI.Label(new Rect(x + 16, y + 4, 250, 18), "CLASSIFICATION IA (SVM)", sT);

        string etatTxt = "INCONNU"; Color etatCol = GRIS;
        if (receiver.etat_ia == 1) { etatTxt = "SAIN"; etatCol = VERT; }
        else if (receiver.etat_ia == 2) { etatTxt = "DEFAUT FAIBLE"; etatCol = ORANGE; }
        else if (receiver.etat_ia == 3) { etatTxt = "DEFAUT GRAVE"; etatCol = ROUGE; }

        GUI.DrawTexture(new Rect(x + w - 115, y + 4, 107, 18), Tx(new Color(etatCol.r, etatCol.g, etatCol.b, 0.2f)));
        GUIStyle es = new GUIStyle(sS) { fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter, fontSize = 11 };
        es.normal.textColor = etatCol; GUI.Label(new Rect(x + w - 115, y + 4, 107, 18), etatTxt, es);

        y += 26; float bW = (w - 30) / 3;
        DrawBarIA(x + 8, y, bW, "Sain", receiver.proba_sain, VERT);
        DrawBarIA(x + 8 + bW + 4, y, bW, "Faible", receiver.proba_faible, ORANGE);
        DrawBarIA(x + 8 + (bW + 4) * 2, y, bW, "Grave", receiver.proba_grave, ROUGE);
        return y + 52;
    }

    void DrawBarIA(float x, float y, float w, string nom, float p, Color c)
    {
        GUIStyle ns = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 }; ns.normal.textColor = GRIS_CLAIR;
        GUI.Label(new Rect(x, y, w, 12), nom, ns);
        float bY = y + 13, bH = 14;
        GUI.DrawTexture(new Rect(x, bY, w, bH), tBar);
        GUI.DrawTexture(new Rect(x, bY, w * Mathf.Clamp01(p / 100f), bH), TxC(c));
        GUIStyle ps = new GUIStyle(sV) { fontSize = 10, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold };
        ps.normal.textColor = BLANC; GUI.Label(new Rect(x, bY, w, bH), p.ToString("F0") + "%", ps);
        if (p > 50)
        {
            GUIStyle ds = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 8, fontStyle = FontStyle.Bold };
            ds.normal.textColor = c; GUI.Label(new Rect(x, bY + bH + 1, w, 12), "DETECTE", ds);
        }
    }

    // ═══════════ RUL PRÉDICTIF ═══════════
    float DrawRUL(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 95), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), Tx(ROUGE));
        GUIStyle titre = new GUIStyle(sT); titre.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(x + 16, y + 4, 280, 18), "MAINTENANCE PREDICTIVE (RUL)", titre);

        string etatTxt = "EN ATTENTE"; Color etatCol = GRIS;
        if (receiver.etat_rul == 1) { etatTxt = "PAS DE PANNE"; etatCol = VERT; }
        else if (receiver.etat_rul == 2) { etatTxt = "SURVEILLER"; etatCol = ORANGE; }
        else if (receiver.etat_rul == 3) { etatTxt = "PANNE PROCHE"; etatCol = ORANGE; }
        else if (receiver.etat_rul == 4) { etatTxt = "CRITIQUE <24H"; etatCol = ROUGE; }

        GUI.DrawTexture(new Rect(x + w - 115, y + 4, 107, 18), Tx(new Color(etatCol.r, etatCol.g, etatCol.b, 0.2f)));
        GUIStyle es = new GUIStyle(sS) { fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter, fontSize = 10 };
        es.normal.textColor = etatCol; GUI.Label(new Rect(x + w - 115, y + 4, 107, 18), etatTxt, es);

        y += 26; float hw = (w - 24) / 2;

        // Moteur RUL
        DrawRULBar(x + 8, y, hw, "Moteur", receiver.RUL_moteur, receiver.tendance_mot);
        // Réducteur RUL
        DrawRULBar(x + 12 + hw, y, hw, "Reducteur", receiver.RUL_reducteur, receiver.tendance_red);

        return y + 68;
    }

    void DrawRULBar(float x, float y, float w, string nom, float rul, float tendance)
    {
        GUIStyle ns = new GUIStyle(sL) { alignment = TextAnchor.MiddleLeft }; ns.normal.textColor = GRIS_CLAIR;
        GUI.Label(new Rect(x, y, w, 14), nom, ns);

        Color c = rul > 500 ? VERT : rul > 100 ? ORANGE : rul > 24 ? ORANGE : ROUGE;

        // Valeur RUL
        GUIStyle vs = new GUIStyle(sV) { fontSize = 18, alignment = TextAnchor.MiddleCenter };
        vs.normal.textColor = c; vs.fontStyle = FontStyle.Bold;
        string rulTxt = rul >= 9999 ? "---" : rul.ToString("F0") + "h";
        GUI.Label(new Rect(x, y + 14, w, 22), rulTxt, vs);

        // Barre
        float bY = y + 38, bH = 8;
        GUI.DrawTexture(new Rect(x, bY, w, bH), tBar);
        float fill = rul >= 9999 ? 1f : Mathf.Clamp01(rul / 500f);
        GUI.DrawTexture(new Rect(x, bY, w * fill, bH), TxC(c));

        // Tendance
        string tendTxt = tendance > 0.01f ? "+" + tendance.ToString("F2") + "/s" : tendance < -0.01f ? tendance.ToString("F2") + "/s" : "stable";
        Color tendCol = tendance > 0.01f ? ROUGE : tendance < -0.01f ? VERT : GRIS;
        GUIStyle ts = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 };
        ts.normal.textColor = tendCol;
        GUI.Label(new Rect(x, bY + 10, w, 12), tendTxt, ts);
    }

    // ═══════════ FIABILITÉ MTBF WEIBULL ═══════════
    float DrawFiab(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 85), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), tBleu);
        GUIStyle titre = new GUIStyle(sT); titre.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(x + 16, y + 4, 280, 18), "FIABILITE WEIBULL / MTBF", titre);
        y += 26; float hw = (w - 24) / 2;

        DrawFiabItem(x + 8, y, hw, "Moteur", receiver.fiab_moteur, receiver.mtbf_moteur);
        DrawFiabItem(x + 12 + hw, y, hw, "Reducteur", receiver.fiab_reducteur, receiver.mtbf_reducteur);
        return y + 58;
    }

    void DrawFiabItem(float x, float y, float w, string nom, float fiab, float mtbf)
    {
        Color c = fiab > 70 ? VERT : fiab > 40 ? ORANGE : ROUGE;

        GUIStyle ns = new GUIStyle(sL) { alignment = TextAnchor.MiddleLeft }; ns.normal.textColor = GRIS_CLAIR;
        GUI.Label(new Rect(x, y, w, 14), nom, ns);

        // Fiabilité %
        GUIStyle vs = new GUIStyle(sV) { fontSize = 16, alignment = TextAnchor.MiddleCenter };
        vs.normal.textColor = c; vs.fontStyle = FontStyle.Bold;
        GUI.Label(new Rect(x, y + 14, w, 18), fiab.ToString("F0") + "%", vs);

        // Barre fiabilité
        float bY = y + 34, bH = 8;
        GUI.DrawTexture(new Rect(x, bY, w, bH), tBar);
        GUI.DrawTexture(new Rect(x, bY, w * Mathf.Clamp01(fiab / 100f), bH), TxC(c));

        // MTBF
        GUIStyle ms = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 };
        ms.normal.textColor = GRIS;
        GUI.Label(new Rect(x, bY + 10, w, 12), "MTBF: " + mtbf.ToString("F0") + "h", ms);
    }

    // ═══════════ PROBABILITÉ DE PANNE ═══════════
    float DrawProbaSection(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 62), tFond2);
        GUI.DrawTexture(new Rect(x + 8, y + 6, 3, 13), tOrange);
        GUI.Label(new Rect(x + 16, y + 4, 250, 18), "PROBABILITE DE PANNE", sT);
        y += 22; float pW = (w - 30) / 2;
        DrawProba(x + 8, y, pW, "Moteur", proba_moteur);
        DrawProba(x + 8 + pW + 14, y, pW, "Reducteur", proba_reducteur);
        return y + 40;
    }

    void DrawProba(float x, float y, float w, string nom, float p)
    {
        Color c = p < 20 ? VERT : p < 60 ? ORANGE : ROUGE;
        string e = p < 20 ? "Sain" : p < 60 ? "Degrade" : "Critique";
        GUIStyle ns = new GUIStyle(sL) { alignment = TextAnchor.MiddleLeft };
        GUI.Label(new Rect(x, y, 70, 12), nom, ns);
        float bY = y + 14, bH = 16;
        GUI.DrawTexture(new Rect(x, bY, w, bH), tBar);
        GUI.DrawTexture(new Rect(x, bY, w * Mathf.Clamp01(p / 100f), bH), TxC(c));
        GUIStyle ps = new GUIStyle(sV) { fontSize = 11, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold };
        ps.normal.textColor = BLANC; GUI.Label(new Rect(x, bY, w, bH), p.ToString("F0") + "% - " + e, ps);
    }

    // ═══════════ TABLEAU ═══════════
    float DrawTableau(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 18), tFond3);
        GUI.DrawTexture(new Rect(x + 8, y + 3, 3, 12), tBlanc);
        GUI.Label(new Rect(x + 16, y + 1, 250, 16), "TABLEAU DE SURVEILLANCE", sT);
        y += 19;
        GUI.DrawTexture(new Rect(x, y, w, 15), tFond3);
        GUIStyle th = new GUIStyle(sS) { fontStyle = FontStyle.Bold, fontSize = 9 }; th.normal.textColor = CYAN_FONCE;
        GUI.Label(new Rect(x + 6, y, 90, 15), "PARAMETRE", th);
        th.alignment = TextAnchor.MiddleCenter;
        GUI.Label(new Rect(x + 96, y, 55, 15), "VALEUR", th);
        GUI.Label(new Rect(x + 151, y, 50, 15), "ALARME", th);
        GUI.Label(new Rect(x + 201, y, 50, 15), "ARRET", th);
        GUI.Label(new Rect(x + 251, y, 40, 15), "ETAT", th);
        y += 16;

        y = Lig(x, y, w, "T Bob. R", receiver.T_bobA, bobine_alarme, bobine_arret);
        y = Lig(x, y, w, "T Bob. S", receiver.T_bobB, bobine_alarme, bobine_arret);
        y = Lig(x, y, w, "T Bob. T", receiver.T_bobC, bobine_alarme, bobine_arret);
        y = Lig(x, y, w, "T Pal. DE", receiver.T_pal_DE, palier_mot_alarme, palier_mot_arret);
        y = Lig(x, y, w, "T Pal. NDE", receiver.T_pal_NDE, palier_mot_alarme, palier_mot_arret);
        y = Lig(x, y, w, "Vib. Moteur", receiver.vib_moteur, vib_mot_alarme, vib_mot_arret);
        GUI.DrawTexture(new Rect(x + 6, y, w - 12, 1), tLigne); y += 2;
        y = Lig(x, y, w, "T Pal. R1", receiver.T_pal1_red, palier_red_alarme, palier_red_arret);
        y = Lig(x, y, w, "T Pal. R2", receiver.T_pal2_red, palier_red_alarme, palier_red_arret);
        y = Lig(x, y, w, "T Huile", receiver.T_huile, huile_alarme, huile_arret);
        y = Lig(x, y, w, "Vib. Red.", receiver.vib_red, vib_red_alarme, vib_red_arret);
        GUI.DrawTexture(new Rect(x + 6, y, w - 12, 1), tLigne); y += 2;
        y = Lig(x, y, w, "P.Trav G1", receiver.P_hydr1, p_hydr_alarme, p_hydr_arret);
        y = Lig(x, y, w, "P.Trav G2", receiver.P_hydr2, p_hydr_alarme, p_hydr_arret);
        y = Lig(x, y, w, "P.Pomp G1", receiver.pression_pompe1, p_pompe_alarme, p_pompe_arret);
        y = Lig(x, y, w, "P.Pomp G2", receiver.pression_pompe2, p_pompe_alarme, p_pompe_arret);
        y = Lig(x, y, w, "C.Pres G1", receiver.contre_pression1, contre_p_alarme, contre_p_arret);
        y = Lig(x, y, w, "C.Pres G2", receiver.contre_pression2, contre_p_alarme, contre_p_arret);
        return y + 6;
    }

    float Lig(float x, float y, float w, string nom, float val, float al, float ar)
    {
        Color c = GC(val, al, ar); string et = c == VERT ? "OK" : c == ORANGE ? "ALRM" : "STOP";
        GUI.DrawTexture(new Rect(x, y, w, 15), tFond2);
        GUIStyle n = new GUIStyle(sC) { fontSize = 9 }; GUI.Label(new Rect(x + 6, y, 90, 15), nom, n);
        GUIStyle v = new GUIStyle(sC) { fontSize = 9, fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter }; v.normal.textColor = c;
        GUI.Label(new Rect(x + 96, y, 55, 15), val.ToString("F1"), v);
        GUIStyle a1 = new GUIStyle(sC) { fontSize = 9, alignment = TextAnchor.MiddleCenter }; a1.normal.textColor = ORANGE;
        GUI.Label(new Rect(x + 151, y, 50, 15), al.ToString("F0"), a1);
        GUIStyle a2 = new GUIStyle(sC) { fontSize = 9, alignment = TextAnchor.MiddleCenter }; a2.normal.textColor = ROUGE;
        GUI.Label(new Rect(x + 201, y, 50, 15), ar.ToString("F0"), a2);
        GUI.DrawTexture(new Rect(x + 255, y + 1, 36, 12), Tx(new Color(c.r, c.g, c.b, 0.2f)));
        GUIStyle e = new GUIStyle(sC) { fontSize = 9, fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter };
        e.normal.textColor = c; if (c != VERT && !blinkOn) e.normal.textColor = new Color(c.r, c.g, c.b, 0.3f);
        GUI.Label(new Rect(x + 255, y + 1, 36, 12), et, e);
        return y + 16;
    }

    // ═══════════ ALERTES ═══════════
    void DrawAlertes(float x, float y, float w)
    {
        GUI.DrawTexture(new Rect(x, y, w, 18), tFond3);
        GUI.DrawTexture(new Rect(x + 8, y + 3, 3, 12), tRouge);
        GUI.Label(new Rect(x + 16, y + 1, 200, 16), "ALERTES ACTIVES", sT);
        y += 19; bool ok = true;
        ok = !At(ref y, x, w, "T Bob. R", receiver.T_bobA, bobine_alarme, bobine_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Bob. S", receiver.T_bobB, bobine_alarme, bobine_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Bob. T", receiver.T_bobC, bobine_alarme, bobine_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Pal. DE", receiver.T_pal_DE, palier_mot_alarme, palier_mot_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Pal. NDE", receiver.T_pal_NDE, palier_mot_alarme, palier_mot_arret, "C") && ok;
        ok = !At(ref y, x, w, "Vib. Mot", receiver.vib_moteur, vib_mot_alarme, vib_mot_arret, "mm/s") && ok;
        ok = !At(ref y, x, w, "T Pal. R1", receiver.T_pal1_red, palier_red_alarme, palier_red_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Pal. R2", receiver.T_pal2_red, palier_red_alarme, palier_red_arret, "C") && ok;
        ok = !At(ref y, x, w, "T Huile", receiver.T_huile, huile_alarme, huile_arret, "C") && ok;
        ok = !At(ref y, x, w, "Vib. Red", receiver.vib_red, vib_red_alarme, vib_red_arret, "mm/s") && ok;
        ok = !At(ref y, x, w, "P.Trav G1", receiver.P_hydr1, p_hydr_alarme, p_hydr_arret, "bar") && ok;
        ok = !At(ref y, x, w, "P.Trav G2", receiver.P_hydr2, p_hydr_alarme, p_hydr_arret, "bar") && ok;
        if (ok)
        {
            GUIStyle s = new GUIStyle(sL) { alignment = TextAnchor.MiddleCenter }; s.normal.textColor = VERT;
            GUI.Label(new Rect(x, y, w, 18), "Aucune alerte - systeme normal", s);
        }
    }

    bool At(ref float y, float x, float w, string nom, float val, float al, float ar, string u)
    {
        if (val < al) return false; bool stop = val >= ar; Color c = stop ? ROUGE : ORANGE;
        if (blinkOn || !stop)
        {
            GUI.DrawTexture(new Rect(x, y, w, 17), Tx(new Color(c.r, c.g, c.b, 0.12f)));
            GUI.DrawTexture(new Rect(x + 6, y + 6, 5, 5), TxC(c));
            GUIStyle a = new GUIStyle(sC) { fontSize = 9 }; a.normal.textColor = c;
            GUI.Label(new Rect(x + 16, y, 100, 17), nom, a); a.alignment = TextAnchor.MiddleCenter; a.fontStyle = FontStyle.Bold;
            GUI.Label(new Rect(x + 120, y, 80, 17), val.ToString("F1") + " " + u, a); a.alignment = TextAnchor.MiddleRight;
            GUI.Label(new Rect(x + w - 60, y, 54, 17), stop ? "ARRET" : "ALARME", a);
        }
        y += 18; return true;
    }

    // ═══════════ COURBE TREND ═══════════
    void DrawCourbe()
    {
        if (!historique.ContainsKey(courbeActive) || historique[courbeActive].Count < 2) return;
        float gW = Screen.width - 440, gH = 180, gX = 10, gY = Screen.height - gH - 10;
        GUI.DrawTexture(new Rect(gX, gY, gW, gH), tFond);
        GUIStyle ts = new GUIStyle(sT); ts.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(gX + 10, gY + 4, 300, 18), "TREND : " + courbeActive, ts);
        GUIStyle btn = new GUIStyle(GUI.skin.button) { fontSize = 12, fontStyle = FontStyle.Bold };
        if (GUI.Button(new Rect(gX + gW - 120, gY + 3, 30, 18), "+", btn)) zoomCourbe = Mathf.Min(zoomCourbe * 1.5f, 10f);
        if (GUI.Button(new Rect(gX + gW - 85, gY + 3, 30, 18), "-", btn)) zoomCourbe = Mathf.Max(zoomCourbe / 1.5f, 0.2f);
        if (GUI.Button(new Rect(gX + gW - 50, gY + 3, 40, 18), "X", btn)) { courbeActive = ""; return; }

        float zX = gX + 50, zY = gY + 26, zW = gW - 65, zH = gH - 36;
        GUI.DrawTexture(new Rect(zX, zY, zW, zH), Tx(new Color(0.05f, 0.08f, 0.12f)));
        List<float> data = historique[courbeActive];
        float minV = float.MaxValue, maxV = float.MinValue;
        int count = data.Count, start = Mathf.Max(0, count - (int)(120 / zoomCourbe));
        for (int i = start; i < count; i++) { if (data[i] < minV) minV = data[i]; if (data[i] > maxV) maxV = data[i]; }
        float margin = (maxV - minV) * 0.15f; if (margin < 1f) margin = 5f; minV -= margin; maxV += margin;

        float alarme = 0, arret = 0; TS(courbeActive, ref alarme, ref arret);
        if (alarme > 0 && arret > 0) { if (arret > maxV) maxV = arret + margin; if (alarme < minV) minV = alarme - margin; }

        for (int i = 0; i <= 4; i++)
        {
            float gy2 = zY + zH * (1f - i / 4f);
            GUI.DrawTexture(new Rect(zX, gy2, zW, 1), Tx(new Color(0.15f, 0.2f, 0.25f)));
            GUIStyle gs = new GUIStyle(sS) { alignment = TextAnchor.MiddleRight, fontSize = 9 }; gs.normal.textColor = GRIS;
            GUI.Label(new Rect(gX, gy2 - 6, 45, 12), (minV + (maxV - minV) * (i / 4f)).ToString("F0"), gs);
        }

        if (alarme > 0 && alarme >= minV && alarme <= maxV)
        {
            float ay = zY + zH * (1f - (alarme - minV) / (maxV - minV));
            for (float dx = 0; dx < zW; dx += 8) GUI.DrawTexture(new Rect(zX + dx, ay, 4, 1), tOrange);
            GUIStyle as2 = new GUIStyle(sS) { fontSize = 9 }; as2.normal.textColor = ORANGE; GUI.Label(new Rect(zX + zW + 2, ay - 6, 40, 12), "AL", as2);
        }
        if (arret > 0 && arret >= minV && arret <= maxV)
        {
            float ay = zY + zH * (1f - (arret - minV) / (maxV - minV));
            for (float dx = 0; dx < zW; dx += 8) GUI.DrawTexture(new Rect(zX + dx, ay, 4, 1), tRouge);
            GUIStyle ar2 = new GUIStyle(sS) { fontSize = 9 }; ar2.normal.textColor = ROUGE; GUI.Label(new Rect(zX + zW + 2, ay - 6, 40, 12), "AR", ar2);
        }

        int nb = count - start; if (nb < 2) return; float step = zW / (float)(nb - 1);
        for (int i = 1; i < nb; i++)
        {
            float v1 = data[start + i - 1], v2 = data[start + i];
            float x1 = zX + (i - 1) * step, x2 = zX + i * step;
            float y1 = zY + zH * (1f - (v1 - minV) / (maxV - minV)), y2 = zY + zH * (1f - (v2 - minV) / (maxV - minV));
            DL(x1, y1, x2, y2);
        }

        float lastV = data[count - 1], lastYp = zY + zH * (1f - (lastV - minV) / (maxV - minV));
        GUI.DrawTexture(new Rect(zX + zW - 3, lastYp - 3, 6, 6), tCyan);
        GUIStyle vss = new GUIStyle(sV) { fontSize = 12, alignment = TextAnchor.MiddleLeft }; vss.normal.textColor = CYAN_VIF;
        GUI.Label(new Rect(zX + zW + 4, lastYp - 8, 60, 16), lastV.ToString("F1"), vss);
        GUIStyle ts2 = new GUIStyle(sS) { alignment = TextAnchor.MiddleCenter, fontSize = 9 }; ts2.normal.textColor = GRIS;
        GUI.Label(new Rect(zX, zY + zH + 1, 40, 12), "-" + nb + "s", ts2);
        GUI.Label(new Rect(zX + zW - 40, zY + zH + 1, 40, 12), "Now", ts2);
    }

    void DL(float x1, float y1, float x2, float y2)
    {
        float dx = x2 - x1, dy = y2 - y1, len = Mathf.Sqrt(dx * dx + dy * dy);
        if (len < 0.5f) return; float angle = Mathf.Atan2(dy, dx) * Mathf.Rad2Deg;
        GUIUtility.RotateAroundPivot(angle, new Vector2(x1, y1));
        GUI.DrawTexture(new Rect(x1, y1 - 1, len, 2), tCyan);
        GUIUtility.RotateAroundPivot(-angle, new Vector2(x1, y1));
    }

    void TS(string nom, ref float alarme, ref float arret)
    {
        if (nom.Contains("Bob")) { alarme = bobine_alarme; arret = bobine_arret; }
        else if (nom.Contains("Pal.DE") || nom.Contains("Pal.NDE")) { alarme = palier_mot_alarme; arret = palier_mot_arret; }
        else if (nom.Contains("Vib.Mot")) { alarme = vib_mot_alarme; arret = vib_mot_arret; }
        else if (nom.Contains("Pal.R")) { alarme = palier_red_alarme; arret = palier_red_arret; }
        else if (nom.Contains("Huile")) { alarme = huile_alarme; arret = huile_arret; }
        else if (nom.Contains("Vib.Red")) { alarme = vib_red_alarme; arret = vib_red_arret; }
        else if (nom.Contains("Trav")) { alarme = p_hydr_alarme; arret = p_hydr_arret; }
        else if (nom.Contains("Pres")) { alarme = contre_p_alarme; arret = contre_p_arret; }
        else if (nom.Contains("Pomp")) { alarme = p_pompe_alarme; arret = p_pompe_arret; }
    }

    // ═══════════ CALCULS ═══════════
    void CalcProba()
    {
        float p1 = Dg(receiver.T_bobA, bobine_alarme, bobine_arret);
        float p2 = Dg(receiver.T_bobB, bobine_alarme, bobine_arret);
        float p3 = Dg(receiver.T_bobC, bobine_alarme, bobine_arret);
        float p4 = Dg(receiver.T_pal_DE, palier_mot_alarme, palier_mot_arret);
        float p5 = Dg(receiver.T_pal_NDE, palier_mot_alarme, palier_mot_arret);
        float p6 = Dg(receiver.vib_moteur, vib_mot_alarme, vib_mot_arret);
        proba_moteur = (1f - (1f - p1) * (1f - p2) * (1f - p3) * (1f - p4) * (1f - p5) * (1f - p6)) * 100f;

        float p7 = Dg(receiver.T_pal1_red, palier_red_alarme, palier_red_arret);
        float p8 = Dg(receiver.T_pal2_red, palier_red_alarme, palier_red_arret);
        float p9 = Dg(receiver.T_huile, huile_alarme, huile_arret);
        float p10 = Dg(receiver.vib_red, vib_red_alarme, vib_red_arret);
        proba_reducteur = (1f - (1f - p7) * (1f - p8) * (1f - p9) * (1f - p10)) * 100f;

        float maxP = Mathf.Max(proba_moteur, proba_reducteur);
        etat_global = maxP < 20f ? "SAIN" : maxP < 60f ? "ALARME" : "DANGER";

        if (receiver.etat_ia == 3)
            etat_global = "DANGER";
        else if (receiver.etat_ia == 2 && etat_global == "SAIN")
            etat_global = "ALARME";
    }
    float Dg(float v, float a, float ar) { if (v <= a * 0.8f) return 0f; if (v <= a) return 0.15f; if (v <= ar) return 0.15f + ((v - a) / (ar - a)) * 0.55f; return 0.90f; }
    Color GC(float v, float a, float ar) { if (v >= ar) return ROUGE; if (v >= a) return ORANGE; return VERT; }
}
 
