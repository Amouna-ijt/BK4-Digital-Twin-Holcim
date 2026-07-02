using UnityEngine;
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;

public class SimulinkReceiver : MonoBehaviour
{
    // ================================================================
    // SIGNAUX REÇUS DE SIMULINK
    // Ordre identique à envoyer_donnees.m
    // ================================================================

    // Vitesses
    public float wm;                // index 0
    public float w_table;           // index 1

    // Températures moteur
    public float T_bobA;            // index 2
    public float T_bobB;            // index 3
    public float T_bobC;            // index 4
    public float T_pal_DE;          // index 5
    public float T_pal_NDE;         // index 6

    // Températures réducteur
    public float T_huile;           // index 7
    public float T_pal1_red;        // index 8
    public float T_pal2_red;        // index 9

    // Vibrations
    public float vib_moteur;        // index 10
    public float vib_red;           // index 11

    // Position 
    public float pos_galet;         // index 12
  
    // Vitesse séparateur
    public float w_separateur;      // index 13

   
    // Pressions galets
    public float P_hydr1;           // index 14
    public float P_hydr2;           // index 15

    // Pressions pompes
    public float pression_pompe1;   // index 16
    public float pression_pompe2;   // index 17

    // Contre pressions
    public float contre_pression1;  // index 18
    public float contre_pression2;  // index 19

    // IA Classification
    public float etat_ia;           // index 20
    public float proba_sain;        // index 21
    public float proba_faible;      // index 22
    public float proba_grave;       // index 23

    // RUL Prédictif
    public float RUL_moteur;        // index 24
    public float RUL_reducteur;     // index 25
    public float tendance_mot;      // index 26
    public float tendance_red;      // index 27
    public float etat_rul;          // index 28

    // Fiabilité et MTBF
    public float fiab_moteur;       // index 29
    public float fiab_reducteur;    // index 30
    public float mtbf_moteur;       // index 31
    public float mtbf_reducteur;    // index 32

    // ================================================================
    // UDP
    // ================================================================
    private const int NB_SIGNAUX = 33; // 33 signaux × 8 bytes = 280 bytes
    private const int PORT = 25001;

    private UdpClient udpClient;
    private Thread thread;
    private bool running = false;
    private readonly object _lock = new object();
    private float[] buffer = new float[NB_SIGNAUX];

    // ================================================================
    void Start()
    {
        udpClient = new UdpClient(PORT);
        running = true;
        thread = new Thread(ThreadReception);
        thread.IsBackground = true;
        thread.Start();
        Debug.Log($"SimulinkReceiver démarré sur port {PORT}");
        Debug.Log($"Attente de {NB_SIGNAUX} signaux ({NB_SIGNAUX * 8} bytes)");
    }

    // ================================================================
    void ThreadReception()
    {
        IPEndPoint ep = new IPEndPoint(IPAddress.Any, 0);

        while (running)
        {
            try
            {
                byte[] data = udpClient.Receive(ref ep);

                // Debug : affiche la taille du paquet
                 Debug.Log($"Paquet reçu : {data.Length} bytes");

                // Vérifie la taille minimale
                int tailleAttendue = NB_SIGNAUX * 8;
                if (data.Length < tailleAttendue)
                {
                    Debug.LogWarning($"Paquet trop petit: {data.Length}/{tailleAttendue} bytes");
                    continue;
                }

                // Décode les NB_SIGNAUX doubles
                float[] temp = new float[NB_SIGNAUX];
                for (int i = 0; i < NB_SIGNAUX; i++)
                {
                    byte[] b = new byte[8];
                    Array.Copy(data, i * 8, b, 0, 8);
                    // Pas de reverse car envoyer_donnees envoie en little-endian
                    temp[i] = (float)BitConverter.ToDouble(b, 0);
                }

                lock (_lock) { buffer = temp; }
            }
            catch (SocketException) { break; }
            catch (Exception e)
            {
                if (running)
                    Debug.LogWarning($"UDP Receiver: {e.Message}");
            }
        }
    }

    // ================================================================
    void Update()
    {
        lock (_lock)
        {
            wm = buffer[0];
            w_table = buffer[1];
            T_bobA = buffer[2];
            T_bobB = buffer[3];
            T_bobC = buffer[4];
            T_pal_DE = buffer[5];
            T_pal_NDE = buffer[6];
            T_huile = buffer[7];
            T_pal1_red = buffer[8];
            T_pal2_red = buffer[9];
            vib_moteur = buffer[10];
            vib_red = buffer[11];
            pos_galet = buffer[12];
            w_separateur = buffer[13];
            P_hydr1 = buffer[14];
            P_hydr2 = buffer[15];
            pression_pompe1 = buffer[16];
            pression_pompe2 = buffer[17];
            contre_pression1 = buffer[18];
            contre_pression2 = buffer[19];
            etat_ia = buffer[20];
            proba_sain = buffer[21];
            proba_faible = buffer[22];
            proba_grave = buffer[23];
            RUL_moteur = buffer[24];
            RUL_reducteur = buffer[25];
            tendance_mot = buffer[26];
            tendance_red = buffer[27];
            etat_rul = buffer[28];
            fiab_moteur = buffer[29];
            fiab_reducteur = buffer[30];
            mtbf_moteur = buffer[31];
            mtbf_reducteur = buffer[32];
        }
    }

    // ================================================================
    void OnApplicationQuit()
    {
        running = false;
        udpClient?.Close();
        thread?.Abort();
    }
}
