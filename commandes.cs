using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Globalization;

public class BK4_Commandes : MonoBehaviour
{
    [Header("=== CONNEXION ===")]
    public SimulinkReceiver receiver;

    private UdpClient client;
    private string simulinkIP = "127.0.0.1";

    // États des commandes
    private bool moteurMarche = true;
    private float cmd_vib = 0f;   // 0=SAIN, 30=FAIBLE, 60=GRAVE
    private float cmd_defaut = 0f;   // suit cmd_vib
    private float gain_charge = 40f;  // 40=SAIN, 500=FAIBLE/GRAVE
    private bool urgence = false;

    // Couleurs thème
    private Color CYAN_VIF = new Color(0f, 0.85f, 0.85f);
    private Color FOND = new Color(0.06f, 0.1f, 0.14f, 0.96f);
    private Color FOND2 = new Color(0.08f, 0.14f, 0.18f, 0.97f);
    private Color LIGNE = new Color(0.15f, 0.25f, 0.3f);
    private Color BLANC = new Color(0.92f, 0.94f, 0.96f);
    private Color GRIS = new Color(0.6f, 0.6f, 0.65f);
    private Color VERT = new Color(0.18f, 0.8f, 0.35f);
    private Color ROUGE = new Color(0.92f, 0.25f, 0.25f);
    private Color ORANGE = new Color(0.95f, 0.65f, 0.1f);

    private Texture2D tFond, tFond2, tLigne;
    private GUIStyle sTitle, sLabel, sValue;
    private bool stylesOK = false;

    // ================================================================
    void Start()
    {
        client = new UdpClient();
        tFond = Tx(FOND);
        tFond2 = Tx(FOND2);
        tLigne = Tx(LIGNE);

        // Envoyer valeurs initiales (état SAIN)
        EnvoyerUDP(30001, 1f);   // cmd_marche = 1
        EnvoyerUDP(30003, 0f);   // cmd_defaut = 0
        EnvoyerUDP(30004, 0f);   // cmd_vib    = 0
        EnvoyerUDP(30005, 40f);  // gain_charge = 40
    }

    // ================================================================
    Texture2D Tx(Color c)
    {
        Texture2D t = new Texture2D(1, 1);
        t.SetPixel(0, 0, c);
        t.Apply();
        return t;
    }

    // ================================================================
    void EnvoyerUDP(int port, float valeur)
    {
        string msg = valeur.ToString("F4", CultureInfo.InvariantCulture);
        byte[] data = Encoding.UTF8.GetBytes(msg);
        try { client.Send(data, data.Length, simulinkIP, port); }
        catch { }
    }

    // ================================================================
    void InitStyles()
    {
        if (stylesOK) return;
        stylesOK = true;

        sTitle = new GUIStyle(GUI.skin.label)
        { fontSize = 14, fontStyle = FontStyle.Bold };
        sTitle.normal.textColor = CYAN_VIF;

        sLabel = new GUIStyle(GUI.skin.label) { fontSize = 12 };
        sLabel.normal.textColor = BLANC;

        sValue = new GUIStyle(GUI.skin.label)
        { fontSize = 12, fontStyle = FontStyle.Bold };
        sValue.alignment = TextAnchor.MiddleRight;
    }

    // ================================================================
    void OnGUI()
    {
        InitStyles();

        float W = 280, x = 10, y = 10, h = 360;

        // Fond principal
        GUI.DrawTexture(new Rect(x - 5, y - 5, W + 10, h + 10), tFond);

        // ── Titre ──
        GUI.Label(new Rect(x + 8, y, 250, 24), "COMMANDES BK4", sTitle);

        // ── Indicateur marche ──
        string connTxt = moteurMarche ? "MOTEUR EN MARCHE" : "MOTEUR ARRETE";
        Color connCol = moteurMarche ? VERT : ROUGE;
        GUIStyle cs = new GUIStyle(sLabel)
        {
            fontSize = 9,
            fontStyle = FontStyle.Bold,
            alignment = TextAnchor.MiddleCenter
        };
        cs.normal.textColor = connCol;
        GUI.DrawTexture(new Rect(x + W - 120, y + 2, 112, 18),
            Tx(new Color(connCol.r, connCol.g, connCol.b, 0.2f)));
        GUI.Label(new Rect(x + W - 120, y + 2, 112, 18), connTxt, cs);
        y += 28;

        GUI.DrawTexture(new Rect(x + 8, y, W - 16, 1), tLigne);
        y += 8;

        // ══════════ MARCHE / ARRÊT ══════════
        GUI.DrawTexture(new Rect(x + 5, y, W - 10, 42), tFond2);
        GUI.Label(new Rect(x + 10, y + 2, 200, 16), "Moteur principal", sLabel);
        y += 18;

        float btnW = (W - 30) / 2;
        GUIStyle btnS = new GUIStyle(GUI.skin.button)
        { fontSize = 13, fontStyle = FontStyle.Bold };

        // Bouton DEMARRER / ARRETER
        GUI.backgroundColor = moteurMarche ? ROUGE : VERT;
        string btnTxt = moteurMarche ? "ARRETER" : "DEMARRER";
        if (GUI.Button(new Rect(x + 10, y, btnW, 22), btnTxt, btnS))
        {
            moteurMarche = !moteurMarche;
            EnvoyerUDP(30001, moteurMarche ? 1f : 0f);
        }

        // Bouton RESET
        GUI.backgroundColor = ORANGE;
        if (GUI.Button(new Rect(x + 15 + btnW, y, btnW, 22), "RESET", btnS))
        {
            moteurMarche = true;
            cmd_vib = 0f;
            cmd_defaut = 0f;
            gain_charge = 40f;
            urgence = false;
            EnvoyerUDP(30001, 1f);
            EnvoyerUDP(30003, 0f);
            EnvoyerUDP(30004, 0f);
            EnvoyerUDP(30005, 40f);
        }
        GUI.backgroundColor = Color.white;
        y += 30;

        // ══════════ DÉGRADATION (cmd_vib) ══════════
        GUI.DrawTexture(new Rect(x + 5, y, W - 10, 58), tFond2);

        string etatTxt = cmd_vib < 20f ? "SAIN" :
                         cmd_vib < 45f ? "FAIBLE" : "GRAVE";
        Color etatCol = cmd_vib < 20f ? VERT :
                         cmd_vib < 45f ? ORANGE : ROUGE;
        sValue.normal.textColor = etatCol;

        GUI.Label(new Rect(x + 10, y + 2, 150, 16), "Etat degradation", sLabel);
        GUI.Label(new Rect(x + W - 80, y + 2, 70, 16), etatTxt, sValue);
        y += 20;

        float newVib = GUI.HorizontalSlider(
            new Rect(x + 10, y, W - 20, 20), cmd_vib, 0f, 60f);

        if (Mathf.Abs(newVib - cmd_vib) > 0.1f)
        {
            cmd_vib = newVib;
            cmd_defaut = newVib;
            gain_charge = (cmd_vib > 5f) ? 500f : 40f;
            EnvoyerUDP(30003, cmd_defaut);
            EnvoyerUDP(30004, cmd_vib);
            EnvoyerUDP(30005, gain_charge);
        }
        y += 20;

        // Labels slider dégradation
        GUIStyle sl = new GUIStyle(sLabel) { fontSize = 9 };
        sl.normal.textColor = GRIS;
        sl.alignment = TextAnchor.MiddleLeft;
        GUI.Label(new Rect(x + 10, y, 40, 14), "SAIN", sl);
        sl.alignment = TextAnchor.MiddleCenter;
        GUI.Label(new Rect(x + W / 2 - 20, y, 50, 14), "FAIBLE", sl);
        sl.alignment = TextAnchor.MiddleRight;
        GUI.Label(new Rect(x + W - 50, y, 40, 14), "GRAVE", sl);
        y += 20;

        // ══════════ BOUTONS RAPIDES ══════════
        GUI.DrawTexture(new Rect(x + 5, y, W - 10, 42), tFond2);
        GUI.Label(new Rect(x + 10, y + 2, 200, 16), "Etat rapide", sLabel);
        y += 18;

        float bw3 = (W - 30) / 3;

        // Bouton SAIN
        GUI.backgroundColor = VERT;
        if (GUI.Button(new Rect(x + 10, y, bw3, 22), "SAIN", btnS))
        {
            cmd_vib = 0f;
            cmd_defaut = 0f;
            gain_charge = 40f;
            EnvoyerUDP(30003, 0f);
            EnvoyerUDP(30004, 0f);
            EnvoyerUDP(30005, 40f);
        }

        // Bouton FAIBLE
        GUI.backgroundColor = ORANGE;
        if (GUI.Button(new Rect(x + 15 + bw3, y, bw3, 22), "FAIBLE", btnS))
        {
            cmd_vib = 30f;
            cmd_defaut = 30f;
            gain_charge = 500f;
            EnvoyerUDP(30003, 30f);
            EnvoyerUDP(30004, 30f);
            EnvoyerUDP(30005, 500f);
        }

        // Bouton GRAVE
        GUI.backgroundColor = ROUGE;
        if (GUI.Button(new Rect(x + 20 + bw3 * 2, y, bw3, 22), "GRAVE", btnS))
        {
            cmd_vib = 60f;
            cmd_defaut = 60f;
            gain_charge = 500f;
            EnvoyerUDP(30003, 60f);
            EnvoyerUDP(30004, 60f);
            EnvoyerUDP(30005, 500f);
        }
        GUI.backgroundColor = Color.white;
        y += 30;

        // ══════════ AFFICHAGE VALEURS ACTUELLES ══════════
        GUI.DrawTexture(new Rect(x + 5, y, W - 10, 52), tFond2);
        GUIStyle sv2 = new GUIStyle(sLabel) { fontSize = 11 };
        sv2.normal.textColor = GRIS;
        GUI.Label(new Rect(x + 10, y + 2, 250, 16), "Commandes envoyees :", sv2);
        y += 18;
        sv2.normal.textColor = BLANC;
        GUI.Label(new Rect(x + 10, y, 250, 16),
            $"cmd_vib={cmd_vib:F0}  cmd_def={cmd_defaut:F0}  gain={gain_charge:F0}", sv2);
        y += 16;
        GUI.Label(new Rect(x + 10, y, 250, 16),
            $"marche={moteurMarche}  urgence={urgence}", sv2);
        y += 20;

        // ══════════ ARRÊT D'URGENCE ══════════
        y += 5;
        GUI.backgroundColor = urgence ? new Color(0.5f, 0f, 0f) : ROUGE;
        GUIStyle urgS = new GUIStyle(GUI.skin.button)
        { fontSize = 16, fontStyle = FontStyle.Bold };

        string urgTxt = urgence ? "URGENCE ACTIVE - CLIQUER RESET" : "ARRET D'URGENCE";
        if (GUI.Button(new Rect(x + 5, y, W - 10, 40), urgTxt, urgS))
        {
            urgence = !urgence;
            if (urgence)
            {
                moteurMarche = false;
                cmd_vib = 0f;
                cmd_defaut = 0f;
                gain_charge = 40f;
                EnvoyerUDP(30001, 0f);
                EnvoyerUDP(30003, 0f);
                EnvoyerUDP(30004, 0f);
                EnvoyerUDP(30005, 40f);
            }
            else
            {
                moteurMarche = true;
                EnvoyerUDP(30001, 1f);
            }
        }
        GUI.backgroundColor = Color.white;

        // Clignotement urgence
        if (urgence)
        {
            if (Mathf.Sin(Time.time * 6f) > 0)
                GUI.DrawTexture(new Rect(x + 5, y + 42, W - 10, 3), Tx(ROUGE));
        }
    }

    // ================================================================
    void OnApplicationQuit()
    {
        if (client != null) client.Close();
    }
}
