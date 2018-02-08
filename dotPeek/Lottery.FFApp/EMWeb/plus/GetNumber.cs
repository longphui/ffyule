﻿// Decompiled with JetBrains decompiler
// Type: Lottery.EMWeb.plus.GetNumber
// Assembly: Lottery.FFApp, Version=1.0.1.1, Culture=neutral, PublicKeyToken=null
// MVID: CD5F1C7F-2EB9-4806-9452-C9F3634A8986
// Assembly location: F:\pros\tianheng\bf\WebAppOld\bin\Lottery.FFApp.dll

using Lottery.DAL;
using System;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;
using System.Web.UI;

namespace Lottery.EMWeb.plus
{
  public class GetNumber : Page
  {
    private string strNumberUrl = ConfigurationManager.AppSettings["NumberUrl"].ToString();

    protected void Page_Load(object sender, EventArgs e)
    {
      this.Response.ContentType = "text/html; charset=utf-8";
      this.Response.Write(GetNumber.GetHtml(this.strNumberUrl + "/Data/GetJsonData.aspx?lid=" + this.Request.QueryString["lid"].ToString() + "&callback=" + this.Request.QueryString["callback"].ToString()));
    }

    public static string GetHtml(string Url)
    {
      string str = "";
      try
      {
        HttpWebRequest httpWebRequest = (HttpWebRequest) WebRequest.Create(Url);
        httpWebRequest.Method = "GET";
        httpWebRequest.UserAgent = "MSIE";
        httpWebRequest.ContentType = "application/x-www-form-urlencoded";
        str = new StreamReader(httpWebRequest.GetResponse().GetResponseStream(), Encoding.UTF8).ReadToEnd();
      }
      catch
      {
        new LogExceptionDAL().Save("采集异常", "数据源地址：" + Url);
      }
      return str;
    }
  }
}
