using UnityEngine;

public class BK4_Rotation : MonoBehaviour
{
    [Header("=== CONNEXION ===")]
    public SimulinkReceiver receiver;

    [Header("=== PIÈCES ===")]
    public Transform moteur;
    public Transform reducteur;
    public Transform separateur;
    public Transform galet1;
    public Transform galet2;
    public Transform table;

    [Header("=== MULTIPLICATEUR VISUEL ===")]
    public float boostMoteur = 50f;
    public float boostTable = 100f;
    public float boostGalet = 100f;
    public float boostSeparateur = 80f;

    [Header("=== RÉGLAGES ===")]
    public float facteur = 0.1f;
    public float rapportReduction = 38.65f;

    [Header("=== RENDERERS COULEURS ===")]
    public Renderer moteurRenderer;
    public Renderer reducteurRenderer;
    public Renderer galet1Renderer;
    public Renderer galet2Renderer;
    public Renderer tableRenderer;
    public Renderer separateurRenderer;

    [Header("=== SEUILS MOTEUR ===")]
    public float bobine_alarme = 100f;
    public float bobine_arret = 120f;
    public float palier_mot_alarme = 85f;
    public float palier_mot_arret = 95f;
    public float vib_mot_alarme = 6.5f;
    public float vib_mot_arret = 7.1f;

    [Header("=== SEUILS RÉDUCTEUR ===")]
    public float palier_red_alarme = 70f;
    public float palier_red_arret = 75f;
    public float huile_alarme = 70f;
    public float huile_arret = 75f;
    public float vib_red_alarme = 4f;
    public float vib_red_arret = 5f;

    [Header("=== SEUILS PRESSION ===")]
    public float p_hydr_alarme = 160f;
    public float p_hydr_arret = 180f;

    private Color VERT = Color.green;
    private Color ORANGE = new Color(1f, 0.5f, 0f);
    private Color ROUGE = Color.red;
    private MaterialPropertyBlock propBlock;

    void Start()
    {
        propBlock = new MaterialPropertyBlock();
    }

    void Update()
    {
        if (receiver == null) return;
        float dt = Time.deltaTime;

        // ===== ROTATIONS =====
        if (moteur != null)
            moteur.Rotate(receiver.wm * facteur * boostMoteur * dt, 0, 0);

        if (reducteur != null)
            reducteur.Rotate(receiver.wm * facteur * boostMoteur * dt, 0, 0);

        if (table != null)
            table.Rotate(0, 0, (receiver.wm / rapportReduction) * facteur * boostTable * dt);

        if (galet1 != null)
            galet1.Rotate(0, (receiver.wm / rapportReduction) * facteur * boostGalet * dt, 0);

        if (galet2 != null)
            galet2.Rotate(0, (receiver.wm / rapportReduction) * facteur * boostGalet * dt, 0);

        if (separateur != null)
            separateur.Rotate(receiver.w_separateur * facteur * boostSeparateur * dt, 0, 0);

        // ===== COULEURS =====

        // MOTEUR : basé sur bobines + paliers + vibrations
        float maxBob = Mathf.Max(receiver.T_bobA, Mathf.Max(receiver.T_bobB, receiver.T_bobC));
        float maxPalMot = Mathf.Max(receiver.T_pal_DE, receiver.T_pal_NDE);
        Color cMoteur = PireCouleur(
            GetCouleur(maxBob, bobine_alarme, bobine_arret),
            GetCouleur(maxPalMot, palier_mot_alarme, palier_mot_arret),
            GetCouleur(Mathf.Abs(receiver.vib_moteur), vib_mot_alarme, vib_mot_arret)
        );
        SetCouleur(moteurRenderer, cMoteur);

        // RÉDUCTEUR : basé sur paliers + huile + vibrations
        float maxPalRed = Mathf.Max(receiver.T_pal1_red, receiver.T_pal2_red);
        Color cRed = PireCouleur(
            GetCouleur(maxPalRed, palier_red_alarme, palier_red_arret),
            GetCouleur(receiver.T_huile, huile_alarme, huile_arret),
            GetCouleur(Mathf.Abs(receiver.vib_red), vib_red_alarme, vib_red_arret)
        );
        SetCouleur(reducteurRenderer, cRed);

        // GALET 1 : basé sur pression galet 1
        Color cGalet1 = GetCouleur(receiver.P_hydr1, p_hydr_alarme, p_hydr_arret);
        SetCouleur(galet1Renderer, cGalet1);

        // GALET 2 : basé sur pression galet 2
        Color cGalet2 = GetCouleur(receiver.P_hydr2, p_hydr_alarme, p_hydr_arret);
        SetCouleur(galet2Renderer, cGalet2);

        // TABLE : suit le pire état entre moteur et réducteur
        Color cTable = PireCouleur(cMoteur, cRed, VERT);
        SetCouleur(tableRenderer, cTable);

        // SÉPARATEUR : suit l'état global de l'IA
        Color cSep = VERT;
        if (receiver.etat_ia == 2) cSep = ORANGE;
        else if (receiver.etat_ia == 3) cSep = ROUGE;
        SetCouleur(separateurRenderer, cSep);
    }

    Color GetCouleur(float val, float alarme, float arret)
    {
        if (val >= arret) return ROUGE;
        if (val >= alarme) return ORANGE;
        return VERT;
    }

    Color PireCouleur(Color a, Color b, Color c)
    {
        if (a == ROUGE || b == ROUGE || c == ROUGE) return ROUGE;
        if (a == ORANGE || b == ORANGE || c == ORANGE) return ORANGE;
        return VERT;
    }

    void SetCouleur(Renderer rend, Color c)
    {
        if (rend == null) return;
        rend.GetPropertyBlock(propBlock);
        propBlock.SetColor("_Color", c);
        propBlock.SetColor("_BaseColor", c);
        rend.SetPropertyBlock(propBlock);
    }
}
