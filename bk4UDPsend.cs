using System;
using System.Net.Sockets;
using UnityEngine;

/// <summary>
/// Envoi des commandes depuis Unity vers Simulink
/// </summary>
public class BK4_UDPSender : MonoBehaviour
{
    [Header("=== CONNEXION SIMULINK ===")]
    public string ipSimulink = "127.0.0.1";
    public int portMarche = 30001;
    public int portDefaut = 30003;
    public int portVib = 30004;
    public int portGainCharge = 30005;

    [Header("=== COMMANDES ACTUELLES ===")]
    [Range(0f, 1f)] public float cmd_marche = 1f;
    [Range(0f, 60f)] public float cmd_defaut = 0f;
    [Range(0f, 60f)] public float cmd_vib = 0f;
    public float gain_charge = 40f;

    private UdpClient udpClient;
    private float timer = 0f;
    public float intervalleEnvoi = 0.1f; // 10 Hz

    // ================================================================
    void Start()
    {
        udpClient = new UdpClient();
        Debug.Log("BK4_UDPSender démarré !");
    }

    // ================================================================
    void Update()
    {
        timer += Time.deltaTime;
        if (timer >= intervalleEnvoi)
        {
            timer = 0f;
            EnvoyerToutesCommandes();
        }
    }

    // ================================================================
    // ENVOI DE TOUTES LES COMMANDES
    // ================================================================
    public void EnvoyerToutesCommandes()
    {
        EnvoyerDouble(portMarche, cmd_marche);
        EnvoyerDouble(portDefaut, cmd_defaut);
        EnvoyerDouble(portVib, cmd_vib);
        EnvoyerDouble(portGainCharge, gain_charge);
    }

    void EnvoyerDouble(int port, double valeur)
    {
        try
        {
            byte[] data = BitConverter.GetBytes(valeur);
            if (BitConverter.IsLittleEndian) Array.Reverse(data);
            udpClient.Send(data, data.Length, ipSimulink, port);
        }
        catch (Exception e)
        {
            Debug.LogWarning($"Erreur envoi port {port}: {e.Message}");
        }
    }

    // ================================================================
    // MÉTHODES PUBLIQUES - appelées depuis Dashboard ou boutons
    // ================================================================
    public void SetEtatSain()
    {
        cmd_vib = 0f;
        cmd_defaut = 0f;
        gain_charge = 40f;
        EnvoyerToutesCommandes();
        Debug.Log("→ Simulink : SAIN");
    }

    public void SetEtatFaible()
    {
        cmd_vib = 30f;
        cmd_defaut = 30f;
        gain_charge = 500f;
        EnvoyerToutesCommandes();
        Debug.Log("→ Simulink : FAIBLE");
    }

    public void SetEtatGrave()
    {
        cmd_vib = 60f;
        cmd_defaut = 60f;
        gain_charge = 500f;
        EnvoyerToutesCommandes();
        Debug.Log("→ Simulink : GRAVE");
    }

    public void SetMarche(bool marche)
    {
        cmd_marche = marche ? 1f : 0f;
        EnvoyerToutesCommandes();
        Debug.Log($"→ Simulink : {(marche ? "MARCHE" : "ARRET")}");
    }

    public void SetCmdVib(float valeur)
    {
        cmd_vib = Mathf.Clamp(valeur, 0f, 60f);
        gain_charge = (valeur > 5f) ? 500f : 40f;
        EnvoyerToutesCommandes();
    }

    // ================================================================
    void OnDestroy()
    {
        udpClient?.Close();
    }
}
