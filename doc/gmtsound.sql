/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50621
Source Host           : localhost:3306
Source Database       : gmtsound

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

Date: 2017-04-24 15:31:15
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for admin
-- ----------------------------
DROP TABLE IF EXISTS `admin`;
CREATE TABLE `admin` (
  `adminID` int(11) NOT NULL AUTO_INCREMENT,
  `adminName` varchar(30) NOT NULL DEFAULT '',
  `adminPSW` varchar(32) NOT NULL DEFAULT '',
  `adminLevel` int(1) NOT NULL DEFAULT '0',
  `fatherAdminID` int(11) NOT NULL DEFAULT '0',
  `createTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`adminID`),
  KEY `adminName` (`adminName`) USING BTREE,
  KEY `adminPSW` (`adminPSW`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for building
-- ----------------------------
DROP TABLE IF EXISTS `building`;
CREATE TABLE `building` (
  `buildingID` int(11) NOT NULL AUTO_INCREMENT,
  `buildingName` varchar(255) NOT NULL DEFAULT '',
  `buildAddress` varchar(255) NOT NULL DEFAULT '',
  `createTime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`buildingID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for company
-- ----------------------------
DROP TABLE IF EXISTS `company`;
CREATE TABLE `company` (
  `companyID` int(11) NOT NULL AUTO_INCREMENT,
  `buildingID` int(11) NOT NULL DEFAULT '0',
  `companyName` varchar(255) NOT NULL DEFAULT '',
  `companyTelephone` varchar(30) NOT NULL DEFAULT '',
  `companyUrl` varchar(255) NOT NULL DEFAULT '',
  `companyLogoUrl` varchar(255) NOT NULL DEFAULT '',
  `companyLocation` varchar(255) NOT NULL DEFAULT '',
  `createTime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`companyID`),
  KEY `buildingID` (`buildingID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for device
-- ----------------------------
DROP TABLE IF EXISTS `device`;
CREATE TABLE `device` (
  `deviceID` int(11) NOT NULL AUTO_INCREMENT,
  `requireID` int(11) NOT NULL DEFAULT '0',
  `groupID` int(11) NOT NULL DEFAULT '0',
  `deviceName` varchar(30) NOT NULL DEFAULT '',
  `createTime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`deviceID`),
  KEY `requireID` (`requireID`),
  KEY `groupID` (`groupID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for devicegroup
-- ----------------------------
DROP TABLE IF EXISTS `devicegroup`;
CREATE TABLE `devicegroup` (
  `groupID` int(11) NOT NULL AUTO_INCREMENT,
  `groupName` varchar(30) NOT NULL DEFAULT '',
  `fatherGroupID` int(11) NOT NULL DEFAULT '0',
  `createTime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`groupID`),
  KEY `fatherGroupID` (`fatherGroupID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for require
-- ----------------------------
DROP TABLE IF EXISTS `require`;
CREATE TABLE `require` (
  `requireID` int(11) NOT NULL AUTO_INCREMENT,
  `requireName` varchar(30) NOT NULL DEFAULT '',
  `requireDeScript` varchar(255) NOT NULL DEFAULT '',
  `createTime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `isDelete` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`requireID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
