﻿using System;
using Lottery.DAL;

namespace Lottery.Web.report
{
	public class userHistoryPop : AdminCenter
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			base.Admin_Load("", "html");
		}
	}
}
