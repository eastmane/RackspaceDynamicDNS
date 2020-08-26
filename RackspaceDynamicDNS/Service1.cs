using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using RackspaceDNSService;
using System.Timers;
using System.Threading;
using log4net;
using log4net.Config;

namespace RackspaceDynamicDNS
{
    public partial class Service1 : ServiceBase
    {
        System.Threading.Timer updateTimer;
        private static readonly ILog log = LogManager.GetLogger(typeof(RackspaceDNSService.RackspaceDNSService));

        public Service1()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            XmlConfigurator.Configure();

            updateTimer = new System.Threading.Timer(
                new TimerCallback(updateDNS), null, 30000, 
                Convert.ToInt32(ConfigurationManager.AppSettings["TimerPeriodInMinutes"]) * 1000 * 60);

            log.Info("RackspaceDynamicDNS Started");
        }

        private void updateDNS(object stateInfo)
        {
            try
            {
                var dnsSvc = new RackspaceDNSService.RackspaceDNSService(log);
                dnsSvc.Authenticate(ConfigurationManager.AppSettings["Username"], ConfigurationManager.AppSettings["APIKey"]);
                dnsSvc.UpdateIPAddressForARecord(ConfigurationManager.AppSettings["Domain"], ConfigurationManager.AppSettings["Host"], Utilities.GetPublicIP());
            }
            catch (Exception ex)
            {
                log.Error(ex);
            }
        }

        protected override void OnStop()
        {
            updateTimer.Dispose();
        }
    }
}
