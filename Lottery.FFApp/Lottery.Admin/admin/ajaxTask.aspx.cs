﻿// Decompiled with JetBrains decompiler
// Type: Lottery.Admin.ajaxTask
// Assembly: Lottery.Admin, Version=7.0.1.203, Culture=neutral, PublicKeyToken=null
// MVID: 838B9BD2-8091-4C2A-B624-E2A206486676
// Assembly location: F:\pros\tianheng\bf\admin\bin\Lottery.Admin.dll

using Lottery.DAL;
using Lottery.Utils;
using System;
using System.Data;

namespace Lottery.Admin
{
  public partial class ajaxTask : AdminCenter
  {
    private string _operType = string.Empty;
    private string _response = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
      if (!this.CheckFormUrl())
        this.Response.End();
      this.Admin_Load("master", "json");
      this._operType = this.q("oper");
      switch (this._operType)
      {
        case "ajaxGetList":
          this.ajaxGetList();
          break;
        case "ajaxStates":
          this.ajaxStates();
          break;
        case "ajaxDel":
          this.ajaxDel();
          break;
        case "ajaxSave":
          this.ajaxSave();
          break;
        default:
          this.DefaultResponse();
          break;
      }
      this.Response.Write(this._response);
    }

    private void DefaultResponse()
    {
      this._response = this.JsonResult(0, "未知操作");
    }

    private void ajaxGetList()
    {
      int num1 = this.Int_ThisPage();
      int num2 = this.Str2Int(this.q("pagesize"), 20);
      this.Str2Int(this.q("flag"), 0);
      string whereStr = "";
      this.doh.Reset();
      this.doh.ConditionExpress = whereStr;
      int totalCount = this.doh.Count("Sys_TaskSet");
      string sql0 = SqlHelp.GetSql0("*", "Sys_TaskSet", "Sort", num2, num1, "asc", whereStr);
      this.doh.Reset();
      this.doh.SqlCmd = sql0;
      DataTable dataTable = this.doh.GetDataTable();
      this._response = "{\"result\" :\"1\",\"returnval\" :\"操作成功\",\"pagebar\" :\"" + PageBar.GetPageBar(3, "js", 2, totalCount, num2, num1, "javascript:ajaxList(<#page#>);") + "\"," + dtHelp.DT2JSON(dataTable) + "}";
      dataTable.Clear();
      dataTable.Dispose();
    }

    private void ajaxStates()
    {
      string str = this.f("id");
      this.doh.Reset();
      this.doh.ConditionExpress = "id=@id";
      this.doh.AddConditionParameter("@id", (object) str);
      int int32 = Convert.ToInt32(this.doh.GetField("Sys_TaskSet", "IsUsed"));
      this.doh.Reset();
      this.doh.ConditionExpress = "id=" + str;
      this.doh.AddFieldItem("IsUsed", (object) (int32 == 0 ? 1 : 0));
      if (this.doh.Update("Sys_TaskSet") > 0)
        this._response = this.JsonResult(1, "设置成功");
      else
        this._response = this.JsonResult(0, "设置失败");
    }

    private void ajaxDel()
    {
      string str = this.f("id");
      this.doh.Reset();
      this.doh.ConditionExpress = "id=" + str;
      if (this.doh.Delete("Sys_TaskSet") > 0)
        this._response = this.JsonResult(1, "操作成功");
      else
        this._response = this.JsonResult(0, "操作失败");
    }

    private void ajaxSave()
    {
      string str = this.f("rank");
      this.doh.Reset();
      this.doh.ConditionExpress = "id=1";
      this.doh.AddFieldItem("AutoRanking", (object) str);
      if (this.doh.Update("Sys_Info") > 0)
        this._response = this.JsonResult(1, "设置成功");
      else
        this._response = this.JsonResult(0, "设置失败");
    }
  }
}
