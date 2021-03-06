﻿using System;
using System.Text.RegularExpressions;

namespace Lottery.Utils
{
	public static class CheckPK10_3Start
	{
		public static int PK10_3FS(string LotteryNumber, string CheckNumber)
		{
			int num = 0;
			string[] array = LotteryNumber.Split(new char[]
			{
				','
			});
			LotteryNumber = string.Concat(new string[]
			{
				array[0],
				",",
				array[1],
				",",
				array[2]
			});
			string[] array2 = LotteryNumber.Split(new char[]
			{
				','
			});
			string[] array3 = CheckNumber.Split(new char[]
			{
				','
			});
			Regex regex = new Regex("^[_0-9]+$");
			if (regex.IsMatch(array3[0]) && regex.IsMatch(array3[1]) && regex.IsMatch(array3[2]))
			{
				if (array3.Length == 3 && array3[0].IndexOf(array2[0]) != -1 && array3[1].IndexOf(array2[1]) != -1 && array3[2].IndexOf(array2[2]) != -1)
				{
					num++;
				}
			}
			else
			{
				num = 0;
			}
			return num;
		}

		public static int PK10_3DS(string LotteryNumber, string CheckNumber)
		{
			int num = 0;
			string[] array = LotteryNumber.Split(new char[]
			{
				','
			});
			LotteryNumber = array[0] + array[1] + array[2];
			string[] array2 = CheckNumber.Replace(" ", "").Split(new char[]
			{
				','
			});
			for (int i = 0; i < array2.Length; i++)
			{
				Regex regex = new Regex("^[_0-9]+$");
				if (!regex.IsMatch(array2[i]))
				{
					return 0;
				}
				if (LotteryNumber == array2[i])
				{
					num++;
				}
			}
			return num;
		}
	}
}
