﻿using log4net;
using Lottery.DAL;
using Lottery.DBUtility;
using Lottery.Entity;
using Lottery.Utils;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace Lottery.Collect.Sys
{
    /// <summary>
    /// 系统彩
    /// </summary>
    public abstract class SysBase
    {
        private static readonly ILog Log = LogManager.GetLogger(typeof(SysBase));
        protected static LotteryDataDAL _lotteryDataDal = new LotteryDataDAL();
        protected static LotteryDAL _sysLotteryDal = new LotteryDAL();

        #region 
        /// <summary>
        /// 奖种Ids
        /// </summary>
        public int Id
        {
            get
            {
                if (this.SysLottery != null)
                {
                    return this.SysLottery.Id;
                }

                throw new Exception("彩种配置信息异常");
            }
        }

        /// <summary>
        /// 奖种编号
        /// </summary>
        public string Code { get; set; }

        /// <summary>
        /// 奖种配置
        /// </summary>
        public SysLotteryModel SysLottery { get; set; }

        /// <summary>
        /// 所有开奖号码
        /// </summary>
        public string NumberAll { get; set; }

        /// <summary>
        /// 开奖号每位长度
        /// </summary>
        public int NumberAllSize { get; set; }


        /// <summary>
        /// 所有开奖号总数
        /// </summary>
        public int NumberAllCount { get; set; }

        /// <summary>
        /// 开奖号码
        /// </summary>
        public string Number { get; set; }

        /// <summary>
        /// 开奖号总数
        /// </summary>
        public int NumberCount { get; set; }

        /// <summary>
        /// 当前期号
        /// </summary>
        public int Expect { get; set; }

        /// <summary>
        /// 当前期号
        /// </summary>
        public string ExpectNo { get; set; }

        /// <summary>
        /// 上一期号
        /// </summary>
        public string LastExpect { get; set; }

        /// <summary>
        /// 开奖时间
        /// </summary>
        public string OpenTime { get; set; }

        #endregion

        /// <summary>
        /// 彩种编码
        /// </summary>
        /// <param name="code"></param>
        public SysBase(string code)
        {
            this.Code = code;

            if (!string.IsNullOrEmpty(this.Code))
            {
                this.SysLottery = _sysLotteryDal.GetSysLotteryByCode(this.Code);
            }
        }

        /// <summary>
        /// 初使化彩种期号
        /// </summary>
        public void UpdateExpect()
        {
            try
            {
                //上一期开奖时间已结束，才生成本期号码
                if (!string.IsNullOrEmpty(this.OpenTime) && Convert.ToDateTime(this.OpenTime) >= DateTime.Now)
                {
                    return;
                }

                if (this.SysLottery == null)
                {
                    throw new Exception("无效的彩种配置");
                }

                using (SqlConnection conn = new SqlConnection(Const.ConnectionString))
                {
                    using (DbOperHandler doh = new SqlDbOperHandler(conn))
                    {
                        string ltId = this.SysLottery.Id.ToString();
                        //DateTime curDateTime = GetDateTime(); //当前日期时间
                        DateTime curDateTime = DateTime.Now; //当前日期时间
                        string curDate = curDateTime.ToString("yyyyMMdd"); //当前日期
                        string curTime = curDateTime.ToString("HH:mm:ss"); //当前时间

                        string curNum = ""; //当前期数
                        string curExpect; //当前期号
                        DateTime openTime = DateTime.Now; //当前开奖时间

                        if (UserCenterSession.LotteryTime == null)
                        {
                            UserCenterSession.LotteryTime = new LotteryTimeDAL().GetTable(); //开奖时间
                        }

                        DataRow[] dataRowArray2 = UserCenterSession.LotteryTime.Select("Time <'" + curTime + "' and LotteryId=" + ltId, "Time desc");

                        if (dataRowArray2.Length == 0)
                        {
                            dataRowArray2 = UserCenterSession.LotteryTime.Select("LotteryId=" + ltId, "Time desc");
                            curExpect = curDateTime.AddDays(-1.0).ToString("yyyyMMdd") + "-" + dataRowArray2[0]["Sn"].ToString();
                            curNum = dataRowArray2[0]["Sn"].ToString();
                            openTime = Convert.ToDateTime(dataRowArray2[0]["Time"].ToString()); //本期开奖时间
                        }
                        else
                        {
                            curExpect = curDate + "-" + dataRowArray2[0]["Sn"].ToString();
                            curNum = dataRowArray2[0]["Sn"].ToString();
                            openTime = Convert.ToDateTime(dataRowArray2[0]["Time"].ToString()); //本期开奖时间

                            if (curDateTime > Convert.ToDateTime(curDateTime.ToString("yyyy-MM-dd") + " 00:00:00")
                                && curDateTime < Convert.ToDateTime(curDateTime.ToString("yyyy-MM-dd") + " 10:00:01")
                                && ltId == "1003")
                            {
                                //新疆时时彩, 北京时间0点到10点，记为前一天期号
                                curExpect = curDateTime.AddDays(-1.0).ToString("yyyyMMdd") + "-" + dataRowArray2[0]["Sn"].ToString();
                                curNum = dataRowArray2[0]["Sn"].ToString();
                            }
                            if (curDateTime > Convert.ToDateTime(curDateTime.ToString("yyyy-MM-dd") + " 23:00:00")
                                && curDateTime < Convert.ToDateTime(curDateTime.ToString("yyyy-MM-dd") + " 23:59:59")
                                && (ltId == "1014" || ltId == "1016"))
                            {
                                //东京1.5分彩, 北京时间23点，记为下一天期号
                                curExpect = curDateTime.AddDays(1.0).ToString("yyyyMMdd") + "-" + dataRowArray2[0]["Sn"].ToString();
                            }
                        }

                        //韩国1.5分彩, 韩国1.5分3D
                        if (ltId == "1010" || ltId == "1017" || ltId == "3004")
                        {
                            curExpect = string.Concat((object)(new LotteryTimeDAL().GetTsIssueNum(ltId) + Convert.ToInt32(dataRowArray2[0]["Sn"].ToString())));
                            curNum = dataRowArray2[0]["Sn"].ToString();
                        }

                        //新加坡2分彩
                        if (ltId == "1012")
                        {
                            curExpect = string.Concat((object)(new LotteryTimeDAL().GetTsIssueNum("1012") + Convert.ToInt32(dataRowArray2[0]["Sn"].ToString())));
                            curNum = dataRowArray2[0]["Sn"].ToString();
                        }

                        //台湾5分彩
                        if (ltId == "1013")
                        {
                            curExpect = string.Concat((object)(new LotteryTimeDAL().GetTsIssueNum("1013") + Convert.ToInt32(dataRowArray2[0]["Sn"].ToString())));
                            curNum = dataRowArray2[0]["Sn"].ToString();
                        }

                        //东京1.5分彩, 菲律宾1.5分
                        if (ltId == "1014" || ltId == "1015" || ltId == "1016")
                        {
                            curExpect = curExpect.Replace("-", "");
                        }

                        //北京PK10
                        if (ltId == "4001")
                        {
                            curExpect = string.Concat((object)(new LotteryTimeDAL().GetTsIssueNum("4001") + Convert.ToInt32(dataRowArray2[0]["Sn"].ToString())));
                            curNum = dataRowArray2[0]["Sn"].ToString();
                        }

                        this.Expect = Int32.Parse(curNum); //开奖期数
                        this.ExpectNo = curExpect; //当前开奖期号
                        this.OpenTime = openTime.ToString("yyyy-MM-dd HH:mm:ss"); //当前开奖时间

                        //Console.WriteLine("彩种: {0}, 开奖时间: {1}, 期号: {2}, {3}", this.Code, this.OpenTime, this.ExpectNo, this.Expect);
                        //Console.WriteLine("当前时间: {0}", curDateTime.ToString("yyyy-MM-dd HH:mm:ss"));
                        Log.DebugFormat("彩种: {0}, 开奖时间: {1}, 期号: {2}, {3}", this.Code, this.OpenTime, this.ExpectNo, this.Expect);
                        //Log.DebugFormat("当前时间: {0}", curDateTime.ToString("yyyy-MM-dd HH:mm:ss"));
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        /// <summary>
        /// 生成彩票开奖信息
        /// </summary>
        /// <returns></returns>
        public abstract void Generate();

        /// <summary>
        /// 更新彩票开奖信息
        /// </summary>
        /// <param name="type"></param>
        /// <param name="title"></param>
        /// <param name="number"></param>
        /// <param name="opentime"></param>
        /// <param name="numberAll"></param>
        /// <returns></returns>
        public void UpdateLottery()
        {
            try
            {
                //生成开奖号码
                this.Generate();

                //开奖信息入库
                if (_lotteryDataDal.Update(this.SysLottery.Id, this.ExpectNo, this.Number, this.OpenTime, this.NumberAll))
                {
                    Public.SaveLotteryData2File(this.Id);
                    LotteryCheck.RunOfIssueNum(this.Id, this.ExpectNo);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        /// <summary>
        /// 是否开奖
        /// </summary>
        /// <returns></returns>
        //public bool IsLottery()
        //{
        //    DateTime openTime; //下一期开奖时间
        //    if (string.IsNullOrEmpty(this.LastExpect) || !this.LastExpect.Equals(this.ExpectNo) 
        //        || string.IsNullOrEmpty(this.OpenTime) 
        //        || (DateTime.TryParse(this.OpenTime, out openTime) && openTime >= DateTime.Now))
        //    {
        //        return true;
        //    }

        //    return false;
        //}

        /// <summary>
        /// 生成随机数字
        /// </summary>
        /// <returns></returns>
        public static String GetRandomNums(int count)
        {
            var ran = new Random(GetRandomSeed());
            var ranNums = string.Empty;

            for (int i = 0; i < count; i++)
            {
                while (true)
                {
                    var num = ran.Next(0, 10);

                    //单个字符不连续出现
                    if (!ranNums.EndsWith(num.ToString("G")))
                    {
                        ranNums += num;
                        break;
                    }
                }
            }

            return ranNums;
        }

        /// <summary>
        /// 生成随机数字, 不允许重复
        /// </summary>
        /// <returns></returns>
        public static string[] GetRandomNums(string[] source, int count, bool repeatable)
        {
            if (source == null || source.Length <= 0 || count <= 0 || (!repeatable && source.Length < count))
            {
                return null;
            }

            string[] ranNums = new string[count];
            var ran = new Random(GetRandomSeed());

            for (int i = 0; i < count; i++)
            {
                while (true)
                {
                    var index = ran.Next(0, source.Length);
                    var temp = source[index];
                    
                    if (repeatable || !ranNums.Contains(temp))
                    {
                        ranNums[i] = temp;
                        break;
                    }
                }
            }

            return ranNums;
        }

        private static int GetRandomSeed()
        {
            byte[] bytes = new byte[4];
            System.Security.Cryptography.RNGCryptoServiceProvider rng = new System.Security.Cryptography.RNGCryptoServiceProvider();
            rng.GetBytes(bytes);
            return BitConverter.ToInt32(bytes, 0);
        }

        /// <summary>
        /// 系统时间
        /// </summary>
        /// <returns></returns>
        private static DateTime GetDateTime()
        {
            return new DateTimePubDAL().GetDateTime();
        }

    }
}