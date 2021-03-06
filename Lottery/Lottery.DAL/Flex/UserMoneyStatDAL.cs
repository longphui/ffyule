﻿using System;
using System.Data;
using Lottery.DBUtility;
using Lottery.Utils;

namespace Lottery.DAL.Flex
{
	public class UserMoneyStatDAL : ComData
	{
		public void ajaxGetProListSub(string AdminId, int page, int PSize, string whereStr, string UserName, ref string _jsonstr)
		{
			using (DbOperHandler dbOperHandler = new ComData().Doh())
			{
				bool flag = true;
				if (!string.IsNullOrEmpty(UserName))
				{
					dbOperHandler.Reset();
					dbOperHandler.SqlCmd = string.Concat(new string[]
					{
						"select Id from N_User where UserName='",
						UserName,
						"' and UserCode like (select UserCode from N_User where Id=",
						AdminId,
						")+'%'"
					});
					DataTable dataTable = dbOperHandler.GetDataTable();
					if (dataTable.Rows.Count > 0)
					{
						AdminId = dataTable.Rows[0]["Id"].ToString();
					}
					else
					{
						flag = false;
						_jsonstr = "[]";
					}
				}
				if (flag)
				{
					dbOperHandler.Reset();
					dbOperHandler.ConditionExpress = " ParentId = " + AdminId + " or Id=" + AdminId;
					int num = dbOperHandler.Count("N_User");
					string text = string.Format("select {1} as totalcount, {0} as UserID,\r\n                                            (select Convert(varchar(10),cast(round([Point]/10.0,2) as numeric(5,2))) from N_User with(nolock) where Id={0} ) as userpoint,\r\n                                            dbo.f_GetUserName({0}) as userName,\r\n                                            (select isnull(sum(money),0) from N_User with(nolock) where Id = {0}) as money,\r\n                                            isnull(sum(b.Charge),0) Charge,isnull(sum(b.GetCash),0) GetCash,isnull(sum(b.Bet),0)-isnull(sum(b.Cancellation),0) Bet,isnull(sum(b.Point),0) Point,isnull(sum(b.Win),0) Win,isnull(sum(b.Cancellation),0) Cancellation,isnull(sum(b.TranAccIn),0) TranAccIn,isnull(sum(b.TranAccOut),0) TranAccOut,isnull(sum(b.Give),0) Give,isnull(sum(b.Other),0) Other,isnull(sum(b.Change),0) Change,\r\n                                            (isnull(sum(Win),0)+isnull(sum(Point),0)+isnull(sum(Change),0)+isnull(sum(Give),0)+isnull(sum(Cancellation),0))-isnull(sum(Bet),0) as total,\r\n                                            (isnull(sum(Charge),0)-isnull(sum(getcash),0)) as moneytotal\r\n                                            from Flex_UserMoneyStatAll b with(nolock)\r\n                                            where {2} and UserId={0}", AdminId, num, whereStr);
					text += " union all ";
					dbOperHandler.Reset();
					dbOperHandler.SqlCmd = SqlHelp.GetSql0("Id,UserName,Money,Point", "N_User", "ID", PSize, page, "asc", " ParentId = " + AdminId);
					DataTable dataTable = dbOperHandler.GetDataTable();
					for (int i = 0; i < dataTable.Rows.Count; i++)
					{
						string text2 = whereStr + " and UserCode like '%" + Strings.PadLeft(dataTable.Rows[i]["Id"].ToString()) + "%'";
						text += string.Format("select {0} as totalcount, {1} as UserID,\r\n                                            Convert(varchar(10),cast(round({2}/10.0,2) as numeric(5,2))) as userpoint,\r\n                                            '{3}' as userName,\r\n                                            isnull(sum({4}),0)  as money,\r\n                                            isnull(sum(b.Charge),0) Charge,isnull(sum(b.GetCash),0) GetCash,isnull(sum(b.Bet),0)-isnull(sum(b.Cancellation),0)  Bet,isnull(sum(b.Point),0) Point,isnull(sum(b.Win),0) Win,isnull(sum(b.Cancellation),0) Cancellation,isnull(sum(b.TranAccIn),0) TranAccIn,isnull(sum(b.TranAccOut),0) TranAccOut,isnull(sum(b.Give),0) Give,isnull(sum(b.Other),0) Other,isnull(sum(b.Change),0) Change,\r\n                                            (isnull(sum(Win),0)+isnull(sum(Point),0)+isnull(sum(Change),0)+isnull(sum(Give),0)+isnull(sum(Cancellation),0))-isnull(sum(Bet),0) as total,\r\n                                            (isnull(sum(Charge),0)-isnull(sum(getcash),0)) as moneytotal\r\n                                            from Flex_UserMoneyStatAll b with(nolock)\r\n                                            where {5}", new object[]
						{
							num,
							dataTable.Rows[i]["Id"].ToString(),
							dataTable.Rows[i]["Point"].ToString(),
							dataTable.Rows[i]["UserName"].ToString(),
							dataTable.Rows[i]["Money"].ToString(),
							text2
						});
						text += " union all ";
					}
					text += string.Format("select {2} as totalcount, '-1' as UserID,'合计' as userpoint,'' as userName,\r\n                                            (select isnull(sum(money),0) from N_User with(nolock) where UserCode like '%,{0},%') as money,\r\n                                            isnull(sum(b.Charge),0) Charge,isnull(sum(b.GetCash),0) GetCash,isnull(sum(b.Bet),0)-isnull(sum(b.Cancellation),0)  Bet,isnull(sum(b.Point),0) Point,isnull(sum(b.Win),0) Win,isnull(sum(b.Cancellation),0) Cancellation,isnull(sum(b.TranAccIn),0) TranAccIn,isnull(sum(b.TranAccOut),0) TranAccOut,isnull(sum(b.Give),0) Give,isnull(sum(b.Other),0) Other,isnull(sum(b.Change),0) Change,\r\n                                            (isnull(sum(Win),0)+isnull(sum(Point),0)+isnull(sum(Change),0)+isnull(sum(Give),0)+isnull(sum(Cancellation),0))-isnull(sum(Bet),0) as total,\r\n                                            (isnull(sum(Charge),0)-isnull(sum(getcash),0)) as moneytotal\r\n                                            FROM Flex_UserMoneyStatAll b with(nolock) where {1}", AdminId, whereStr + " and UserCode like '%" + Strings.PadLeft(AdminId) + "%'", num);
					dbOperHandler.Reset();
					dbOperHandler.SqlCmd = text;
					dataTable = dbOperHandler.GetDataTable();
					_jsonstr = base.ConverTableToJSON(dataTable);
					dataTable.Clear();
					dataTable.Dispose();
				}
			}
		}

		public void GetTeamTotalList(string AdminId, ref string _jsonstr)
		{
			using (DbOperHandler dbOperHandler = new ComData().Doh())
			{
				string whereStr = "dbo.f_GetUserCode(userId) like '%" + Strings.PadLeft(AdminId) + "%'";
				string sql = SqlHelp.GetSql0(string.Format("[sort],\r\n                                                    [Name],\r\n                                                    isnull(sum(Charge),0) as Charge,\r\n                                                    isnull(sum(getcash),0) as getcash, \r\n                                                    isnull(sum(bet),0) as bet ,\r\n                                                    isnull(sum(win),0) as win,\r\n                                                    isnull(sum(Point),0) as Point,\r\n                                                    isnull(sum(Give),0) as Give,\r\n                                                    isnull(sum(Other),0) as Other,  \r\n                                                    isnull(sum(total),0) as total", AdminId), "V_UserMoneyStatAllUserTotal", "sort", 10, 0, "asc", whereStr, "Name,sort");
				dbOperHandler.Reset();
				dbOperHandler.SqlCmd = sql;
				DataTable dataTable = dbOperHandler.GetDataTable();
				_jsonstr = base.ConverTableToJSON(dataTable);
				dataTable.Clear();
				dataTable.Dispose();
			}
		}

		public void GetUserTotalList(string AdminId, ref string _jsonstr)
		{
			using (DbOperHandler dbOperHandler = new ComData().Doh())
			{
				dbOperHandler.Reset();
				dbOperHandler.SqlCmd = string.Format("select top 1 '1' as Sort,'今日' as Name, isnull(sum(Bet),0)-isnull(sum(Cancellation),0) as bet,isnull(sum(win),0) as win \r\n                                            FROM [N_UserMoneyStatAll] with(nolock) where DateDiff(dd,STime,getdate())=0  and UserId={0}\r\n                                            union all\r\n                                            select top 1 '2' as Sort,'本周' as Name, isnull(sum(Bet),0)-isnull(sum(Cancellation),0) as bet,isnull(sum(win),0) as win \r\n                                            FROM [N_UserMoneyStatAll] with(nolock) where DateDiff(week,STime,getdate())=0  and UserId={0}\r\n                                            union all\r\n                                            select top 1 '3' as Sort,'本月' as Name, isnull(sum(Bet),0)-isnull(sum(Cancellation),0) as bet,isnull(sum(win),0) as win \r\n                                            FROM [N_UserMoneyStatAll] with(nolock) where DateDiff(month,STime,getdate())=0  and UserId={0} \r\n                                            union all\r\n                                            select top 1 '4' as Sort,'总计' as Name, isnull(sum(Bet),0)-isnull(sum(Cancellation),0) as bet,isnull(sum(win),0) as win \r\n                                            FROM [N_UserMoneyStatAll] with(nolock) where   UserId={0}", AdminId);
				DataTable dataTable = dbOperHandler.GetDataTable();
				_jsonstr = base.ConverTableToJSON(dataTable);
				dataTable.Clear();
				dataTable.Dispose();
			}
		}

		public void GetUserRankList(int page, int PSize, ref string _jsonstr)
		{
			using (DbOperHandler dbOperHandler = new ComData().Doh())
			{
				string whereStr = "win>=100";
				string sql = SqlHelp.GetSql0("*", "Flex_BetBank", "win", PSize, page, "desc", whereStr);
				dbOperHandler.Reset();
				dbOperHandler.SqlCmd = sql;
				DataTable dataTable = dbOperHandler.GetDataTable();
				_jsonstr = base.ConverTableToJSON(dataTable);
				dataTable.Clear();
				dataTable.Dispose();
			}
		}

		public string GetUserRankXML()
		{
			string result = "";
			using (DbOperHandler dbOperHandler = new ComData().Doh())
			{
				dbOperHandler.SqlCmd = "select top 5 * from Flex_BetBank where win>=100  order by win desc";
				DataTable dataTable = dbOperHandler.GetDataTable();
				result = base.ConverTableToJSON(dataTable);
				dataTable.Clear();
				dataTable.Dispose();
			}
			return result;
		}
	}
}
