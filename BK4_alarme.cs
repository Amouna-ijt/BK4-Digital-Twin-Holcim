using UnityEngine;

public class BK4_Alarmes : MonoBehaviour
{
    public SimulinkReceiver receiver;

    public Renderer moteurRenderer;
    public Renderer reducteurRenderer;
    public Renderer galetRenderer;
    public Renderer tableRenderer;

    // Couleurs
    private Color vert = Color.green;
    private Color orange = new Color(1f, 0.5f, 0f);
    private Color rouge = Color.red;

    void Update()
    {
        if (receiver == null) return;

        // ========== MOTEUR ==========
        // T° Bobines : alarme 100, arrêt 120
        float maxBob = Mathf.Max(receiver.T_bobA, Mathf.Max(receiver.T_bobB, receiver.T_bobC));
        Color cBob = Seuil(maxBob, 100f, 120f);

        // T° Paliers moteur : alarme 85, arrêt 95
        float maxPalMot = Mathf.Max(receiver.T_pal_DE, receiver.T_pal_NDE);
        Color cPalMot = Seuil(maxPalMot, 85f, 95f);

        // Vibration moteur : alarme 6.5, arrêt 7.10
        Color cVibMot = Seuil(receiver.vib_moteur, 6.5f, 7.1f);

        // La pire couleur pour le moteur
        SetCouleur(moteurRenderer, Pire(cBob, cPalMot, cVibMot));

        // ========== REDUCTEUR ==========
        // T° Paliers réducteur : alarme 70, arrêt 75
        float maxPalRed = Mathf.Max(receiver.T_pal1_red, receiver.T_pal2_red);
        Color cPalRed = Seuil(maxPalRed, 70f, 75f);

        // T° Huile : alarme 70, arrêt 75
        Color cHuile = Seuil(receiver.T_huile, 70f, 75f);

        // Vibration réducteur : alarme 4, arrêt 5
        Color cVibRed = Seuil(receiver.vib_red, 4f, 5f);

        SetCouleur(reducteurRenderer, Pire(cPalRed, cHuile, cVibRed));

        // ========== GALET ==========
        // Position galet : alarme si < 55% ou > 105%, arrêt si < 45%
        Color cPos = vert;
        if (receiver.pos_galet < 45f || receiver.pos_galet > 190f)
            cPos = rouge;
        else if (receiver.pos_galet < 55f || receiver.pos_galet > 155f)
            cPos = orange;

      

        
    }

    Color Seuil(float valeur, float alarme, float arret)
    {
        if (valeur >= arret) return rouge;
        if (valeur >= alarme) return orange;
        return vert;
    }

    Color Pire(Color a, Color b, Color c)
    {
        if (a == rouge || b == rouge || c == rouge) return rouge;
        if (a == orange || b == orange || c == orange) return orange;
        return vert;
    }

    void SetCouleur(Renderer rend, Color c)
    {
        if (rend != null)
            rend.material.color = c;
    }
}
